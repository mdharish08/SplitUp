package com.harish.splitup.service;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.access.AccessDeniedException;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.ExpenseDto;
import com.harish.splitup.dto.ExpenseCommentDto;
import com.harish.splitup.dto.CreateExpenseCommentRequestDto;
import com.harish.splitup.dto.SplitDetailsDto;
import com.harish.splitup.entities.Balance;
import com.harish.splitup.entities.Category;
import com.harish.splitup.entities.Comments;
import com.harish.splitup.entities.Expense;
import com.harish.splitup.entities.ExpenseMapping;
import com.harish.splitup.entities.Group;
import com.harish.splitup.entities.SplitDetails;
import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.exception.ExpenseValidationException;
import com.harish.splitup.repositories.BalanceRepository;
import com.harish.splitup.repositories.CategoryRepository;
import com.harish.splitup.repositories.CommentsRepository;
import com.harish.splitup.repositories.ExpenseMappingsRepository;
import com.harish.splitup.repositories.ExpenseRepository;
import com.harish.splitup.repositories.GroupRepository;
import com.harish.splitup.repositories.UserRepository;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ExpenseService {

    private final GroupRepository groupRepository;
    private final ExpenseRepository expenseRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final CommentsRepository commentsRepository;
    private final ExpenseMappingsRepository expenseMappingsRepository;
    private final BalanceRepository balanceRepository;

    @Transactional(readOnly = true)
    public List<ExpenseDto> getGroupExpenseDetails(Long groupId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new NoSuchElementException("Group not found"));
        return group.getExpenses().stream()
                .filter(e -> !e.isTrashed())
                .map(Expense::toDTO)
                .toList();
    }

    @Transactional
    public ExpenseDto createExpense(ExpenseDto dto) {
        if (dto.getCategory() == null || dto.getCategory().getCategoryId() == null) {
            throw new IllegalArgumentException("Category is required");
        }
        if (dto.getUsers() == null || dto.getUsers().isEmpty()) {
            throw new IllegalArgumentException("At least one participant is required");
        }
        if (dto.getCurrencyCode() == null) {
            throw new IllegalArgumentException("Currency code is required");
        }
        if (dto.getExpenseType() == null) {
            throw new IllegalArgumentException("Expense type is required");
        }

        AppConstants.CurrencyCode currencyCode;
        AppConstants.ExpenseType expenseType;
        try {
            currencyCode = AppConstants.CurrencyCode.valueOf(dto.getCurrencyCode());
            expenseType = AppConstants.ExpenseType.valueOf(dto.getExpenseType());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid currencyCode or expenseType: " + e.getMessage());
        }

        Category category = categoryRepository.findById(dto.getCategory().getCategoryId())
                .orElseThrow(() -> new NoSuchElementException("Category not found"));

        Group group = null;
        if (dto.getGroupId() != null) {
            group = groupRepository.findById(dto.getGroupId())
                    .orElseThrow(() -> new NoSuchElementException("Group not found"));
        }

        Expense expense = Expense.builder()
                .withCategory(category)
                .withCost(dto.getCost())
                .withCurrencyCode(currencyCode)
                .withExpenseType(expenseType)
                .withDescription(dto.getDescription())
                .withGroup(group)
                .build();

        List<Long> userIds = dto.getUsers().stream().map(SplitDetailsDto::getUserId).toList();
        Map<Long, SplitUser> userMap = userRepository.findAllById(userIds)
                .stream().collect(Collectors.toMap(SplitUser::getId, Function.identity()));

        Timestamp now = Timestamp.from(Instant.now());
        List<SplitDetails> splitDetails = new ArrayList<>();
        SplitUser paidUser = null;

        for (SplitDetailsDto splitDto : dto.getUsers()) {
            SplitUser user = userMap.get(splitDto.getUserId());
            if (user == null) {
                throw new NoSuchElementException("User not found: " + splitDto.getUserId());
            }
            SplitDetails split = SplitDetails.builder()
                    .withExpense(expense)
                    .withUser(user)
                    .withPaidShare(splitDto.getPaidShare())
                    .withOwedShare(splitDto.getOwedShare())
                    .withNetBalance(splitDto.getPaidShare().subtract(splitDto.getOwedShare()))
                    .withCreatedAt(now)
                    .withUpdatedAt(now)
                    .build();
            splitDetails.add(split);

            if (splitDto.getPaidShare().compareTo(BigDecimal.ZERO) > 0) {
                if (paidUser != null) {
                    throw new IllegalArgumentException("Only one payer per expense is supported");
                }
                paidUser = user;
            }
        }

        if (paidUser == null) {
            throw new ExpenseValidationException("No payer found — exactly one participant must have paidShare > 0");
        }

        expense.setSplitDetails(splitDetails);
        expense.setPaidBy(paidUser);
        expense.setCreatedAt(now);
        expense.setUpdatedAt(now);
        expenseRepository.save(expense);

        List<ExpenseMapping> expenseMappings = userMap.values().stream()
                .map(user -> ExpenseMapping.builder()
                        .withExpense(expense)
                        .withUser(user)
                        .build())
                .toList();
        expenseMappingsRepository.saveAll(expenseMappings);

        updateBalances(paidUser, splitDetails, group);

        return expense.toDTO();
    }

    private void updateBalances(SplitUser paidUser, List<SplitDetails> splitDetails, Group group) {
        List<Long> friendIds = splitDetails.stream()
                .map(s -> s.getUser().getId())
                .filter(id -> !id.equals(paidUser.getId()))
                .toList();

        if (friendIds.isEmpty()) {
            return;
        }

        // Fetch only balances scoped to the same group (or personal if no group)
        Map<Long, Balance> paidToFriendMap;
        Map<Long, Balance> friendToPaidMap;

        if (group != null) {
            long groupId = group.getGroupId();
            paidToFriendMap = balanceRepository
                    .findAllByUserIdAndFriendIdsAndGroupId(paidUser.getId(), friendIds, groupId)
                    .stream().collect(Collectors.toMap(b -> b.getFriend().getId(), Function.identity()));
            friendToPaidMap = balanceRepository
                    .findAllByUserIdsAndFriendIdAndGroupId(friendIds, paidUser.getId(), groupId)
                    .stream().collect(Collectors.toMap(b -> b.getUser().getId(), Function.identity()));
        } else {
            paidToFriendMap = balanceRepository
                    .findPersonalByUserIdAndFriendIds(paidUser.getId(), friendIds)
                    .stream().collect(Collectors.toMap(b -> b.getFriend().getId(), Function.identity()));
            friendToPaidMap = balanceRepository
                    .findPersonalByUserIdsAndFriendId(friendIds, paidUser.getId())
                    .stream().collect(Collectors.toMap(b -> b.getUser().getId(), Function.identity()));
        }

        List<Balance> toSave = new ArrayList<>();
        for (SplitDetails split : splitDetails) {
            if (split.getUser().getId().equals(paidUser.getId()))
                continue;

            // owedShare is always positive: the amount this friend owes the payer
            BigDecimal owed = split.getOwedShare();
            long friendId = split.getUser().getId();

            Balance paidVsFriend = paidToFriendMap.get(friendId);
            Balance friendVsPaid = friendToPaidMap.get(friendId);
            if (paidVsFriend == null || friendVsPaid == null) {
                throw new ExpenseValidationException(
                        "Balance record missing for pair (" + paidUser.getId() + ", " + friendId + ")");
            }
            // Payer is now owed more → increase; friend owes more → decrease their opposite
            // balance
            paidVsFriend.setAmount(paidVsFriend.getAmount().add(owed));
            friendVsPaid.setAmount(friendVsPaid.getAmount().subtract(owed));
            toSave.add(paidVsFriend);
            toSave.add(friendVsPaid);
        }
        balanceRepository.saveAll(toSave);
    }

    @Transactional(readOnly = true)
    public List<ExpenseDto> getUserExpenses(Long userId) {
        if (userId == null) {
            throw new IllegalArgumentException("userId is required");
        }
        return expenseMappingsRepository.findAllExpensesByUserId(userId)
                .stream()
                .map(Expense::toDTO)
                .sorted(Comparator.comparing(ExpenseDto::getCreatedAt,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ExpenseDto> getFriendExpenses(Long userId, Long friendId) {
        if (userId == null || friendId == null) {
            throw new IllegalArgumentException("userId and friendId are required");
        }
        List<SplitUser> users = userRepository.findAllById(Arrays.asList(userId, friendId));
        if (users.stream().noneMatch(u -> u.getId().equals(userId))) {
            throw new NoSuchElementException("User not found: " + userId);
        }
        if (users.stream().noneMatch(u -> u.getId().equals(friendId))) {
            throw new NoSuchElementException("User not found: " + friendId);
        }
        return expenseRepository.findAllExpenseByFriend(userId, friendId)
                .stream().map(Expense::toDTO).toList();
    }

    @Transactional(readOnly = true)
    public ExpenseDto getExpenseById(Long expenseId, String actorEmail) {
        SplitUser actor = requireUserByEmail(actorEmail);
        Expense expense = requireExpenseForParticipant(expenseId, actor.getId());
        return expense.toDTO();
    }

    @Transactional
    public ExpenseDto updateExpense(Long expenseId, ExpenseDto dto, String actorEmail) {
        SplitUser actor = requireUserByEmail(actorEmail);
        Expense expense = requireExpenseForParticipant(expenseId, actor.getId());
        assertCanManageExpense(expense, actor.getId());
        if (expense.isTrashed()) {
            throw new IllegalStateException("Cannot edit a deleted expense. Restore it first.");
        }

        if (dto.getDescription() != null) {
            expense.setDescription(dto.getDescription());
        }
        if (dto.getCost() != null) {
            expense.setCost(dto.getCost());
        }
        if (dto.getCurrencyCode() != null) {
            AppConstants.CurrencyCode currencyCode;
            try {
                currencyCode = AppConstants.CurrencyCode.valueOf(dto.getCurrencyCode());
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Invalid currencyCode: " + dto.getCurrencyCode());
            }
            expense.setCurrencyCode(currencyCode);
        }
        if (dto.getCategory() != null && dto.getCategory().getCategoryId() != null) {
            Category category = categoryRepository.findById(dto.getCategory().getCategoryId())
                    .orElseThrow(() -> new NoSuchElementException("Category not found"));
            expense.setCategory(category);
        }
        if (dto.getExpenseType() != null) {
            try {
                expense.setExpenseType(AppConstants.ExpenseType.valueOf(dto.getExpenseType()));
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Invalid expenseType: " + dto.getExpenseType());
            }
        }

        expense.setUpdatedAt(Timestamp.from(Instant.now()));
        expenseRepository.save(expense);
        return expense.toDTO();
    }

    @Transactional
    public void deleteExpense(Long expenseId, String actorEmail) {
        SplitUser actor = requireUserByEmail(actorEmail);
        Expense expense = requireExpenseForParticipant(expenseId, actor.getId());
        assertCanManageExpense(expense, actor.getId());
        if (expense.isTrashed()) {
            throw new IllegalStateException("Expense already deleted");
        }

        // Reverse balance effects before deleting
        SplitUser paidUser = expense.getPaidBy();
        List<SplitDetails> splitDetails = expense.getSplitDetails();
        Group group = expense.getGroup();
        if (paidUser != null && splitDetails != null && !splitDetails.isEmpty()) {
            reverseBalances(paidUser, splitDetails, group);
        }

        Timestamp now = Timestamp.from(Instant.now());
        expense.setTrashed(true);
        expense.setDeletedBy(actor.getId());
        expense.setDeletedAt(now);
        expense.setUpdatedAt(now);
        expenseRepository.save(expense);
    }

    @Transactional
    public ExpenseDto restoreExpense(Long expenseId, String actorEmail) {
        SplitUser actor = requireUserByEmail(actorEmail);
        Expense expense = requireExpenseForParticipant(expenseId, actor.getId());
        assertCanManageExpense(expense, actor.getId());
        if (!expense.isTrashed()) {
            throw new IllegalStateException("Expense is not deleted");
        }

        SplitUser paidUser = expense.getPaidBy();
        List<SplitDetails> splitDetails = expense.getSplitDetails();
        Group group = expense.getGroup();
        if (paidUser != null && splitDetails != null && !splitDetails.isEmpty()) {
            updateBalances(paidUser, splitDetails, group);
        }

        Timestamp now = Timestamp.from(Instant.now());
        expense.setTrashed(false);
        expense.setDeletedBy(null);
        expense.setDeletedAt(null);
        expense.setUpdatedAt(now);
        expenseRepository.save(expense);
        return expense.toDTO();
    }

    private void reverseBalances(SplitUser paidUser, List<SplitDetails> splitDetails, Group group) {
        List<Long> friendIds = splitDetails.stream()
                .map(s -> s.getUser().getId())
                .filter(id -> !id.equals(paidUser.getId()))
                .toList();

        if (friendIds.isEmpty()) return;

        Map<Long, Balance> paidToFriendMap;
        Map<Long, Balance> friendToPaidMap;

        if (group != null) {
            long groupId = group.getGroupId();
            paidToFriendMap = balanceRepository
                    .findAllByUserIdAndFriendIdsAndGroupId(paidUser.getId(), friendIds, groupId)
                    .stream().collect(Collectors.toMap(b -> b.getFriend().getId(), Function.identity()));
            friendToPaidMap = balanceRepository
                    .findAllByUserIdsAndFriendIdAndGroupId(friendIds, paidUser.getId(), groupId)
                    .stream().collect(Collectors.toMap(b -> b.getUser().getId(), Function.identity()));
        } else {
            paidToFriendMap = balanceRepository
                    .findPersonalByUserIdAndFriendIds(paidUser.getId(), friendIds)
                    .stream().collect(Collectors.toMap(b -> b.getFriend().getId(), Function.identity()));
            friendToPaidMap = balanceRepository
                    .findPersonalByUserIdsAndFriendId(friendIds, paidUser.getId())
                    .stream().collect(Collectors.toMap(b -> b.getUser().getId(), Function.identity()));
        }

        List<Balance> toSave = new ArrayList<>();
        for (SplitDetails split : splitDetails) {
            if (split.getUser().getId().equals(paidUser.getId())) continue;

            BigDecimal owed = split.getOwedShare();
            long friendId = split.getUser().getId();

            Balance paidVsFriend = paidToFriendMap.get(friendId);
            Balance friendVsPaid = friendToPaidMap.get(friendId);
            if (paidVsFriend == null || friendVsPaid == null) {
                throw new ExpenseValidationException(
                        "Balance record missing for pair (" + paidUser.getId() + ", " + friendId + ")");
            }

            // Reverse: payer is owed less, friend owes less
            paidVsFriend.setAmount(paidVsFriend.getAmount().subtract(owed));
            friendVsPaid.setAmount(friendVsPaid.getAmount().add(owed));
            toSave.add(paidVsFriend);
            toSave.add(friendVsPaid);
        }
        balanceRepository.saveAll(toSave);
    }

    @Transactional(readOnly = true)
    public List<ExpenseCommentDto> getExpenseComments(Long expenseId) {
        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new NoSuchElementException("Expense not found"));
        if (expense.isTrashed()) {
            throw new NoSuchElementException("Expense not found");
        }
        return commentsRepository.findAllByExpenseExpenseIdOrderByCreatedAtAsc(expenseId)
                .stream()
                .map(Comments::toDTO)
                .toList();
    }

    @Transactional
    public ExpenseCommentDto addExpenseComment(Long expenseId, String authorEmail, CreateExpenseCommentRequestDto req) {
        if (req == null || req.getContent() == null || req.getContent().isBlank()) {
            throw new IllegalArgumentException("Comment content is required");
        }

        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new NoSuchElementException("Expense not found"));
        if (expense.isTrashed()) {
            throw new IllegalStateException("Cannot comment on a deleted expense");
        }
        SplitUser author = userRepository.findByEmailId(authorEmail)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + authorEmail));

        Timestamp now = Timestamp.from(Instant.now());
        Comments comment = Comments.builder()
                .withExpense(expense)
                .withAddedBy(author)
                .withContent(req.getContent().trim())
                .withCommentType(AppConstants.CommentType.USER)
                .withCreatedAt(now)
                .withUpdatedAt(now)
                .build();
        commentsRepository.save(comment);

        expense.setCommentsCount((int) commentsRepository.countByExpenseExpenseId(expenseId));
        expense.setUpdatedAt(now);
        expenseRepository.save(expense);

        return comment.toDTO();
    }

    @Transactional
    public void deleteExpenseComment(Long expenseId, Long commentId, String authorEmail) {
        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new NoSuchElementException("Expense not found"));
        if (expense.isTrashed()) {
            throw new IllegalStateException("Cannot modify comments on a deleted expense");
        }
        Comments comment = commentsRepository.findByCommentIdAndExpenseExpenseId(commentId, expenseId)
                .orElseThrow(() -> new NoSuchElementException("Comment not found"));
        SplitUser author = userRepository.findByEmailId(authorEmail)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + authorEmail));

        if (!comment.getAddedBy().getId().equals(author.getId())) {
            throw new IllegalStateException("You can only delete your own comments");
        }

        commentsRepository.delete(comment);
        expense.setCommentsCount((int) commentsRepository.countByExpenseExpenseId(expenseId));
        expense.setUpdatedAt(Timestamp.from(Instant.now()));
        expenseRepository.save(expense);
    }

    private SplitUser requireUserByEmail(String email) {
        return userRepository.findByEmailId(email)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + email));
    }

    private Expense requireExpenseForParticipant(Long expenseId, Long actorId) {
        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new NoSuchElementException("Expense not found: " + expenseId));
        boolean participant = expense.getSplitDetails() != null
                && expense.getSplitDetails().stream().anyMatch(sd ->
                sd.getUser() != null && sd.getUser().getId() != null && sd.getUser().getId().equals(actorId));
        if (!participant) {
            throw new AccessDeniedException("You are not part of this expense");
        }
        return expense;
    }

    private void assertCanManageExpense(Expense expense, Long actorId) {
        if (expense.getPaidBy() == null || expense.getPaidBy().getId() == null || !expense.getPaidBy().getId().equals(actorId)) {
            throw new AccessDeniedException("Only the payer can modify this expense");
        }
    }
}

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

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.ExpenseDto;
import com.harish.splitup.dto.SplitDetailsDto;
import com.harish.splitup.entities.Balance;
import com.harish.splitup.entities.Category;
import com.harish.splitup.entities.Expense;
import com.harish.splitup.entities.ExpenseMapping;
import com.harish.splitup.entities.Group;
import com.harish.splitup.entities.SplitDetails;
import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.exception.ExpenseValidationException;
import com.harish.splitup.repositories.BalanceRepository;
import com.harish.splitup.repositories.CategoryRepository;
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
    private final ExpenseMappingsRepository expenseMappingsRepository;
    private final BalanceRepository balanceRepository;

    @Transactional(readOnly = true)
    public List<ExpenseDto> getGroupExpenseDetails(Long groupId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new NoSuchElementException("Group not found"));
        return group.getExpenses().stream().map(Expense::toDTO).toList();
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

        Expense expense = new Expense();
        expense.setCategory(category);
        expense.setCost(dto.getCost());
        expense.setCurrencyCode(currencyCode);
        expense.setExpenseType(expenseType);
        expense.setDescription(dto.getDescription());

        Group group = null;
        if (dto.getGroupId() != null) {
            group = groupRepository.findById(dto.getGroupId())
                    .orElseThrow(() -> new NoSuchElementException("Group not found"));
            expense.setGroup(group);
        }

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
            SplitDetails split = new SplitDetails();
            split.setExpense(expense);
            split.setUser(user);
            split.setPaidShare(splitDto.getPaidShare());
            split.setOwedShare(splitDto.getOwedShare());
            split.setNetBalance(splitDto.getPaidShare().subtract(splitDto.getOwedShare()));
            split.setCreatedAt(now);
            split.setUpdatedAt(now);
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

        List<ExpenseMapping> expenseMappings = userMap.values().stream().map(user -> {
            ExpenseMapping m = new ExpenseMapping();
            m.setExpense(expense);
            m.setUser(user);
            return m;
        }).toList();
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
}

package com.harish.splitup.service;

import com.harish.splitup.dto.ExpenseDto;
import com.harish.splitup.dto.SplitDetailsDto;
import com.harish.splitup.entities.*;
import com.harish.splitup.repositories.*;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ExpenseService {

    @Autowired
    GroupRepository groupRepository;

    @Autowired
    ExpenseRepository expenseRepository;

    @Autowired
    UserRepository userRepository;

    @Autowired
    ExpenseMappingsRepository expenseMappingsRepository;

    @Autowired
    BalanceRepository balanceRepository;

    public List<ExpenseDto> getGroupExpenseDetails(Long groupId){
        Optional<Group> group = groupRepository.findById(groupId);
        if(group.isEmpty()){
            throw new IllegalArgumentException("Group not found");
        }
        return group.get().getExpenses().stream().map(Expense::toDTO).toList();
    }

    @Transactional
    public ExpenseDto createExpense(ExpenseDto dto) {
        Expense expense = new Expense();
        Category category = new Category();
        category.setCategoryId(dto.getCategory().getCategoryId());
        category.setName(dto.getCategory().getCategoryName());
        expense.setCategory(category);
        Long groupId = dto.getGroupId();
        if(groupId != null){
            Optional<Group> group = this.groupRepository.findById(groupId);
            if(group.isEmpty()){
                throw new NoSuchElementException("Mapped group not found");
            }
            expense.setGroup(group.get());
        }
        expense.setCost(dto.getCost());
        expense.setCurrencyCode(dto.getCurrencyCode());
        expense.setDescription(dto.getDescription());
        Set<SplitUser> allUsers = new HashSet<>(this.userRepository.findAllById(dto.getUsers().stream().map(SplitDetailsDto::getUserId).collect(Collectors.toSet())));
        List<SplitDetails> splitDetails = new ArrayList<>();
        for(SplitDetailsDto splitDetailsDto : dto.getUsers()){
            SplitDetails split = new SplitDetails();
            split.setExpense(expense);
            Optional<SplitUser> user = allUsers.stream().filter(usr -> usr.getId().equals(splitDetailsDto.getUserId())).findFirst();
            if(user.isEmpty()){
                throw new NoSuchElementException("User with user id :: " +  splitDetailsDto.getUserId() + " :: not found");
            }
            split.setUser(user.get());
            split.setPaidShare(splitDetailsDto.getPaidShare());
            split.setOwedShare(splitDetailsDto.getOwedShare());
            split.setNetBalance(splitDetailsDto.getOwedShare());
            split.setCreatedAt(Timestamp.from(Instant.now()));
            splitDetails.add(split);
        }
        expense.setSplitDetails(splitDetails);
        expense.setCreatedAt(Timestamp.from(Instant.now()));
        expense.setUpdatedAt(Timestamp.from(Instant.now()));
        this.expenseRepository.save(expense);

        List<ExpenseMapping> expenseMappings = new ArrayList<>();
        for(SplitUser user : allUsers){
            ExpenseMapping expenseMapping = new ExpenseMapping();
            expenseMapping.setExpenseId(expense.getExpenseId());
            expenseMapping.setUserId(user.getId());
            expenseMappings.add(expenseMapping);
        }
        this.expenseMappingsRepository.saveAll(expenseMappings);

        Optional<SplitUser> paidUser = splitDetails.stream()
                .filter(details -> details.getPaidShare() != 0.0)
                .map(SplitDetails::getUser)
                .findFirst();
        if(paidUser.isEmpty()){
            throw new IllegalStateException("Paid user can't be empty");
        }

        SplitUser pUser = paidUser.get();
        List<Long> friends = allUsers.stream()
                .map(SplitUser::getId)
                .filter(id -> !Objects.equals(id, pUser.getId()))
                .toList();
        List<Balance> userVsFriendsBalance = this.balanceRepository.findAllByUserIdAndFriendIds(pUser.getId(),friends);
        List<Balance> friendsVsUserBalance = this.balanceRepository.findAllByUserIdsAndFriendId(friends,pUser.getId());
        for(SplitDetails split : splitDetails){
            if(!split.getUser().getId().equals(pUser.getId())){
                SplitUser friend = split.getUser();
                Balance paidVsFriend = userVsFriendsBalance.stream()
                        .filter(balance -> balance.getUser().equals(pUser) && balance.getFriend().equals(friend))
                        .findFirst().orElseThrow();
                paidVsFriend.setAmount(paidVsFriend.getAmount() + split.getNetBalance());

                Balance friendVsPaid = friendsVsUserBalance.stream()
                        .filter(balance -> balance.getUser().equals(friend) && balance.getFriend().equals(pUser))
                        .findFirst().orElseThrow();

                friendVsPaid.setAmount(friendVsPaid.getAmount() - split.getNetBalance());
            }
        }

        this.balanceRepository.saveAll(userVsFriendsBalance);
        this.balanceRepository.saveAll(friendsVsUserBalance);
        return expense.toDTO();
    }

    public List<ExpenseDto> getFriendExpenses(Long userId,Long friendId) {
        if(userId == null || friendId == null){
            throw new IllegalArgumentException("user id or friend id can't be null");
        }
        List<SplitUser> users = this.userRepository.findAllById(Arrays.asList(userId ,friendId));

        users.stream().filter(usr -> usr.getId().equals(userId)).findFirst().orElseThrow( () -> new IllegalArgumentException("User not found "));
        users.stream().filter(usr -> usr.getId().equals(friendId)).findFirst().orElseThrow( () -> new IllegalArgumentException("friend not found "));

        List<Expense> expenses = this.expenseRepository.findAllExpenseByFriend(userId, friendId);

        return expenses.stream()
                .map(Expense::toDTO)
                .toList();
    }
}

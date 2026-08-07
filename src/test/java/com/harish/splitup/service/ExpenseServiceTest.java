package com.harish.splitup.service;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.CategoryDto;
import com.harish.splitup.dto.ExpenseDto;
import com.harish.splitup.dto.SplitDetailsDto;
import com.harish.splitup.entities.*;
import com.harish.splitup.repositories.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;

@ExtendWith(MockitoExtension.class)
class ExpenseServiceTest {

    @Mock private GroupRepository groupRepository;
    @Mock private ExpenseRepository expenseRepository;
    @Mock private UserRepository userRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private ExpenseMappingsRepository expenseMappingsRepository;
    @Mock private BalanceRepository balanceRepository;

    @InjectMocks
    private ExpenseService expenseService;

    private Category category;
    private SplitUser user1;
    private SplitUser user2;

    @BeforeEach
    void setUp() {
        category = new Category();
        category.setCategoryId(1L);
        category.setName("Food");

        user1 = SplitUser.builder()
                .withId(1L)
                .withFirstName("Alice")
                .withLastName("Smith")
                .withEmailId("alice@example.com")
                .withUserPassWord("encoded")
                .build();

        user2 = SplitUser.builder()
                .withId(2L)
                .withFirstName("Bob")
                .withLastName("Jones")
                .withEmailId("bob@example.com")
                .withUserPassWord("encoded")
                .build();
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private ExpenseDto buildBaseDto() {
        CategoryDto catDto = new CategoryDto();
        catDto.setCategoryId(1L);
        catDto.setCategoryName("Food");

        SplitDetailsDto split1 = new SplitDetailsDto();
        split1.setUserId(1L);
        split1.setPaidShare(new BigDecimal("100.00"));
        split1.setOwedShare(new BigDecimal("50.00"));

        SplitDetailsDto split2 = new SplitDetailsDto();
        split2.setUserId(2L);
        split2.setPaidShare(BigDecimal.ZERO);
        split2.setOwedShare(new BigDecimal("50.00"));

        ExpenseDto dto = new ExpenseDto();
        dto.setCategory(catDto);
        dto.setCurrencyCode("USD");
        dto.setExpenseType("EXPENSE");
        dto.setCost(new BigDecimal("100.00"));
        dto.setDescription("Dinner");
        dto.setUsers(new ArrayList<>(List.of(split1, split2)));
        return dto;
    }

    private void stubPersonalBalances() {
        Balance b1 = Balance.builder()
                .withUser(user1).withFriend(user2)
                .withAmount(BigDecimal.ZERO)
                .withCurrencyCode(AppConstants.CurrencyCode.USD)
                .build();
        Balance b2 = Balance.builder()
                .withUser(user2).withFriend(user1)
                .withAmount(BigDecimal.ZERO)
                .withCurrencyCode(AppConstants.CurrencyCode.USD)
                .build();
        given(balanceRepository.findPersonalByUserIdAndFriendIds(eq(1L), anyList()))
                .willReturn(List.of(b1));
        given(balanceRepository.findPersonalByUserIdsAndFriendId(anyList(), eq(1L)))
                .willReturn(List.of(b2));
    }

    private Expense buildMinimalExpense(Timestamp createdAt) {
        Expense expense = new Expense();
        expense.setCategory(category);
        expense.setPaidBy(user1);
        expense.setCreatedAt(createdAt);
        expense.setCurrencyCode(AppConstants.CurrencyCode.USD);
        expense.setExpenseType(AppConstants.ExpenseType.EXPENSE);
        return expense;
    }

    // ── createExpense ─────────────────────────────────────────────────────────

    @Test
    void createExpense_happyPath_equalSplit() {
        // given
        ExpenseDto dto = buildBaseDto();
        given(categoryRepository.findById(1L)).willReturn(Optional.of(category));
        given(userRepository.findAllById(List.of(1L, 2L))).willReturn(List.of(user1, user2));
        stubPersonalBalances();

        // when
        ExpenseDto result = expenseService.createExpense(dto);

        // then
        then(expenseRepository).should(times(1)).save(any(Expense.class));
        then(expenseMappingsRepository).should(times(1)).saveAll(anyList());
        then(balanceRepository).should(times(1)).saveAll(anyList());
        assertThat(result).isNotNull();
        assertThat(result.getCost()).isEqualByComparingTo("100.00");
    }

    @Test
    void createExpense_missingCategory_throwsIllegalArgument() {
        ExpenseDto dto = buildBaseDto();
        dto.setCategory(null);

        assertThatThrownBy(() -> expenseService.createExpense(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Category is required");

        then(expenseRepository).should(never()).save(any());
    }

    @Test
    void createExpense_emptyUsers_throwsIllegalArgument() {
        ExpenseDto dto = buildBaseDto();
        dto.setUsers(new ArrayList<>());

        assertThatThrownBy(() -> expenseService.createExpense(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("At least one participant is required");
    }

    @Test
    void createExpense_categoryNotFound_throwsNoSuchElement() {
        ExpenseDto dto = buildBaseDto();
        given(categoryRepository.findById(1L)).willReturn(Optional.empty());

        assertThatThrownBy(() -> expenseService.createExpense(dto))
                .isInstanceOf(NoSuchElementException.class)
                .hasMessageContaining("Category not found");
    }

    @Test
    void createExpense_userNotFound_throwsNoSuchElement() {
        // only user1 returned; user2 is missing from the map → NoSuchElementException
        ExpenseDto dto = buildBaseDto();
        given(categoryRepository.findById(1L)).willReturn(Optional.of(category));
        given(userRepository.findAllById(anyList())).willReturn(List.of(user1));

        assertThatThrownBy(() -> expenseService.createExpense(dto))
                .isInstanceOf(NoSuchElementException.class)
                .hasMessageContaining("User not found");
    }

    @Test
    void createExpense_noPayer_throwsIllegalState() {
        ExpenseDto dto = buildBaseDto();
        dto.getUsers().forEach(s -> s.setPaidShare(BigDecimal.ZERO));

        given(categoryRepository.findById(1L)).willReturn(Optional.of(category));
        given(userRepository.findAllById(anyList())).willReturn(List.of(user1, user2));

        assertThatThrownBy(() -> expenseService.createExpense(dto))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("No payer found");
    }

    @Test
    void createExpense_multiplePayers_throwsIllegalArgument() {
        ExpenseDto dto = buildBaseDto();
        // both splits have paidShare > 0
        dto.getUsers().forEach(s -> s.setPaidShare(new BigDecimal("50.00")));

        given(categoryRepository.findById(1L)).willReturn(Optional.of(category));
        given(userRepository.findAllById(anyList())).willReturn(List.of(user1, user2));

        assertThatThrownBy(() -> expenseService.createExpense(dto))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Only one payer");
    }

    @Test
    void createExpense_groupExpense_setsGroupOnExpense() {
        Timestamp now = Timestamp.from(Instant.now());
        Group group = Group.builder()
                .withGroupId(5L)
                .withGroupName("Trip")
                .withGroupType(AppConstants.GroupType.TRIP)
                .withCurrencyCode(AppConstants.CurrencyCode.USD)
                .withCreatedBy(1L)
                .withCreatedAt(now)
                .withUpdatedAt(now)
                .build();

        Balance b1 = Balance.builder()
                .withUser(user1).withFriend(user2)
                .withAmount(BigDecimal.ZERO)
                .withCurrencyCode(AppConstants.CurrencyCode.USD)
                .withGroup(group)
                .build();
        Balance b2 = Balance.builder()
                .withUser(user2).withFriend(user1)
                .withAmount(BigDecimal.ZERO)
                .withCurrencyCode(AppConstants.CurrencyCode.USD)
                .withGroup(group)
                .build();

        ExpenseDto dto = buildBaseDto();
        dto.setGroupId(5L);

        given(categoryRepository.findById(1L)).willReturn(Optional.of(category));
        given(groupRepository.findById(5L)).willReturn(Optional.of(group));
        given(userRepository.findAllById(anyList())).willReturn(List.of(user1, user2));
        given(balanceRepository.findAllByUserIdAndFriendIdsAndGroupId(eq(1L), anyList(), eq(5L)))
                .willReturn(List.of(b1));
        given(balanceRepository.findAllByUserIdsAndFriendIdAndGroupId(anyList(), eq(1L), eq(5L)))
                .willReturn(List.of(b2));

        // when
        expenseService.createExpense(dto);

        // then – the saved Expense must have the group set
        ArgumentCaptor<Expense> captor = ArgumentCaptor.forClass(Expense.class);
        then(expenseRepository).should().save(captor.capture());
        assertThat(captor.getValue().getGroup()).isEqualTo(group);
    }

    // ── getUserExpenses ───────────────────────────────────────────────────────

    @Test
    void getUserExpenses_returnsListSortedByDate() {
        Timestamp older = Timestamp.from(Instant.parse("2024-01-01T10:00:00Z"));
        Timestamp newer = Timestamp.from(Instant.parse("2024-06-01T10:00:00Z"));

        Expense expense1 = buildMinimalExpense(older);
        Expense expense2 = buildMinimalExpense(newer);

        // repository returns older first; service must reverse-sort
        given(expenseMappingsRepository.findAllExpensesByUserId(1L))
                .willReturn(List.of(expense1, expense2));

        // when
        List<ExpenseDto> result = expenseService.getUserExpenses(1L);

        // then – newer should come first
        assertThat(result).hasSize(2);
        assertThat(result.get(0).getCreatedAt()).isEqualTo(newer);
        assertThat(result.get(1).getCreatedAt()).isEqualTo(older);
    }

    @Test
    void getUserExpenses_nullUserId_throwsIllegalArgument() {
        assertThatThrownBy(() -> expenseService.getUserExpenses(null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("userId is required");
    }

    // ── getFriendExpenses ─────────────────────────────────────────────────────

    @Test
    void getFriendExpenses_happyPath() {
        Expense expense = buildMinimalExpense(Timestamp.from(Instant.now()));
        given(userRepository.findAllById(List.of(1L, 2L))).willReturn(List.of(user1, user2));
        given(expenseRepository.findAllExpenseByFriend(1L, 2L)).willReturn(List.of(expense));

        List<ExpenseDto> result = expenseService.getFriendExpenses(1L, 2L);

        assertThat(result).hasSize(1);
        then(expenseRepository).should().findAllExpenseByFriend(1L, 2L);
    }

    @Test
    void getFriendExpenses_nullParams_throwsIllegalArgument() {
        assertThatThrownBy(() -> expenseService.getFriendExpenses(null, 2L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("required");

        assertThatThrownBy(() -> expenseService.getFriendExpenses(1L, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("required");
    }

    // ── getGroupExpenseDetails ────────────────────────────────────────────────

    @Test
    void getGroupExpenseDetails_groupNotFound_throwsNoSuchElement() {
        given(groupRepository.findById(99L)).willReturn(Optional.empty());

        assertThatThrownBy(() -> expenseService.getGroupExpenseDetails(99L))
                .isInstanceOf(NoSuchElementException.class)
                .hasMessageContaining("Group not found");
    }
}

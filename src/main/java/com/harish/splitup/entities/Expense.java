package com.harish.splitup.entities;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.ExpenseDto;
import jakarta.persistence.*;
import lombok.Data;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

@Data
@Entity
public class Expense {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long expenseId;

    @OneToOne
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    private double cost = 0.0;

    private String currencyCode;

    private int commentsCount = 0;

    private boolean transactionConfirmed;

    @Enumerated(EnumType.STRING)
    private AppConstants.ExpenseType expenseType;

    @ManyToOne
    @JoinColumn(name = "group_id")
    private Group group;

    private String description;

    private boolean trashed;

    private Long deletedBy;

    private Timestamp deletedAt;

    private Timestamp updatedAt;

    private Timestamp createdAt;

    @OneToMany(mappedBy = "expense",orphanRemoval = true,cascade = CascadeType.ALL)
    private List<SplitDetails> splitDetails = new ArrayList<>();

    public ExpenseDto toDTO(){
        ExpenseDto expenseDto = new ExpenseDto();
        expenseDto.setExpenseId(this.getExpenseId());
        expenseDto.setCurrencyCode(this.getCurrencyCode());
        expenseDto.setDeletedBy(this.getDeletedBy());
        expenseDto.setCost(this.getCost());
        expenseDto.setDescription(this.getDescription());
        expenseDto.setDeletedAt(this.getDeletedAt());
        expenseDto.setCreatedAt(this.getCreatedAt());
        expenseDto.setUpdatedAt(this.getUpdatedAt());
        expenseDto.setCommentsCount(this.getCommentsCount());
        expenseDto.setTransactionConfirmed(this.isTransactionConfirmed());
        expenseDto.setExpenseType(this.getExpenseType().name());

        expenseDto.setCategory(this.getCategory().toDTO());
        expenseDto.setUsers(this.getSplitDetails().stream().map(SplitDetails::toDTO).toList());
        return expenseDto;
    }

}

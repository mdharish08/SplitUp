package com.harish.splitup.entities;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "expense_mappings")
public class ExpenseMapping {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long mappingId;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private SplitUser user;

    @ManyToOne
    @JoinColumn(name = "expense_id", nullable = false)
    private Expense expense;
}

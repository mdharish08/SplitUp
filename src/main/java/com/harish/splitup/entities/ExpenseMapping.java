package com.harish.splitup.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Table(name = "expense_mappings")
@Builder(setterPrefix = "with")
@NoArgsConstructor
@AllArgsConstructor
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

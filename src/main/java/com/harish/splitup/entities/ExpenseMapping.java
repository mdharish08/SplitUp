package com.harish.splitup.entities;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import lombok.Data;

@Data
@Entity
public class ExpenseMapping {

    @Id @GeneratedValue
    private long mappingId;

    private Long userId;

    private Long expenseId;
}

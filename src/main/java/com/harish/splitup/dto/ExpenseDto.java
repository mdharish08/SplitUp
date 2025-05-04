package com.harish.splitup.dto;

import lombok.Data;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

@Data
public class ExpenseDto {

    private Long expenseId;

    private CategoryDto category;

    private String expenseType;

    private Double cost;

    private String currencyCode;

    private Integer commentsCount = 0;

    private boolean transactionConfirmed ;

    private Long groupId;

    private String description;

    private Long deletedBy;

    private Timestamp deletedAt;

    private Timestamp updatedAt;

    private Timestamp createdAt;

    List<SplitDetailsDto> users = new ArrayList<>();

}

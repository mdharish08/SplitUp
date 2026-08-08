package com.harish.splitup.dto;

import lombok.Data;

import java.sql.Timestamp;

@Data
public class ExpenseCommentDto {

    private Long commentId;
    private Long expenseId;
    private String content;
    private String commentType;
    private Long addedById;
    private String addedByEmail;
    private String addedByName;
    private Timestamp createdAt;
    private Timestamp updatedAt;
}

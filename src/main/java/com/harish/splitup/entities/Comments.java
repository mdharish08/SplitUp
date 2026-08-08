package com.harish.splitup.entities;

import com.harish.splitup.dto.ExpenseCommentDto;
import java.sql.Timestamp;

import com.harish.splitup.constants.AppConstants;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Data;

@Data
@Entity
public class Comments {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long commentId;

    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AppConstants.CommentType commentType;

    @ManyToOne
    @JoinColumn(name = "expense_id", nullable = false)
    private Expense expense;

    @ManyToOne
    @JoinColumn(name = "added_by")
    private SplitUser addedBy;

    private Timestamp createdAt;

    private Timestamp updatedAt;

    public ExpenseCommentDto toDTO() {
        ExpenseCommentDto dto = new ExpenseCommentDto();
        dto.setCommentId(this.getCommentId());
        dto.setExpenseId(this.getExpense() != null ? this.getExpense().getExpenseId() : null);
        dto.setContent(this.getContent());
        dto.setCommentType(this.getCommentType() != null ? this.getCommentType().name() : null);
        dto.setAddedById(this.getAddedBy() != null ? this.getAddedBy().getId() : null);
        dto.setAddedByEmail(this.getAddedBy() != null ? this.getAddedBy().getEmailId() : null);
        dto.setAddedByName(this.getAddedBy() != null ? formatAddedByName() : null);
        dto.setCreatedAt(this.getCreatedAt());
        dto.setUpdatedAt(this.getUpdatedAt());
        return dto;
    }

    private String formatAddedByName() {
        String firstName = this.getAddedBy().getFirstName();
        String lastName = this.getAddedBy().getLastName();
        if (firstName == null && lastName == null) {
            return null;
        }
        if (firstName == null) {
            return lastName;
        }
        if (lastName == null) {
            return firstName;
        }
        return firstName + " " + lastName;
    }

}
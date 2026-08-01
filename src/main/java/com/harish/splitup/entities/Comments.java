package com.harish.splitup.entities;

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

}
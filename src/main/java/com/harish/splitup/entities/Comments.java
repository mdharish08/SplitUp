package com.harish.splitup.entities;

import com.harish.splitup.constants.AppConstants;
import jakarta.persistence.*;
import lombok.Data;

import java.sql.Timestamp;

@Data
@Entity
public class Comments {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long commentId;

    private String content;

    @Column(nullable = false)
    private AppConstants.CommentType commentType;

    @ManyToOne
    @JoinColumn(name = "added_by")
    private SplitUser addedBy;

    private Timestamp createdAt;

    private Timestamp updatedAt;

}

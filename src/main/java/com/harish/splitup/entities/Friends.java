package com.harish.splitup.entities;

import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import jakarta.persistence.*;
import lombok.Builder;
import lombok.Data;

import java.sql.Timestamp;

@Data
@Entity
@Table(name = "friends")
@Builder(setterPrefix = "with")
@JsonIdentityInfo(generator= ObjectIdGenerators.PropertyGenerator.class, property="mappingId")
public class Friends {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long mappingId;

    @OneToOne
    @JoinColumn(name = "user_id",nullable = false)
    private SplitUser user;

    @OneToOne
    @JoinColumn(name = "friend_id",nullable = false)
    private SplitUser friend;

    private Timestamp createdAt;

    private Timestamp updatedAt;

    private boolean trashed;
}

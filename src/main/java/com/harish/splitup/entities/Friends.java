package com.harish.splitup.entities;

import java.sql.Timestamp;

import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Table(name = "friends", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "friend_id"})
})
@Builder(setterPrefix = "with")
@NoArgsConstructor
@AllArgsConstructor
@JsonIdentityInfo(generator = ObjectIdGenerators.PropertyGenerator.class, property = "mappingId")
public class Friends {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long mappingId;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private SplitUser user;

    @ManyToOne
    @JoinColumn(name = "friend_id", nullable = false)
    private SplitUser friend;

    private Timestamp createdAt;

    private Timestamp updatedAt;

    private boolean trashed;
}

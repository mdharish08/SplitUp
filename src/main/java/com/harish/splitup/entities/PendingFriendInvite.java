package com.harish.splitup.entities;

import com.harish.splitup.constants.AppConstants;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.sql.Timestamp;

@Data
@Entity
@Table(name = "pending_friend_invites",
    uniqueConstraints = @UniqueConstraint(columnNames = {"inviter_id", "invitee_email"}))
@Builder(setterPrefix = "with")
@NoArgsConstructor
@AllArgsConstructor
public class PendingFriendInvite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "inviter_id", nullable = false)
    private SplitUser inviter;

    @Column(name = "invitee_email", nullable = false)
    private String inviteeEmail;

    @Enumerated(EnumType.STRING)
    private AppConstants.CurrencyCode currencyCode;

    private Timestamp createdAt;
}

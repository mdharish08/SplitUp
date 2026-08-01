package com.harish.splitup.repositories;

import com.harish.splitup.entities.PendingFriendInvite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PendingFriendInviteRepository extends JpaRepository<PendingFriendInvite, Long> {

    // All invites sent BY a user (for getFriendsMeta — show pending in friends list)
    List<PendingFriendInvite> findAllByInviterId(Long inviterId);

    // All invites FOR an email (for registerUser — process on signup)
    List<PendingFriendInvite> findAllByInviteeEmail(String inviteeEmail);

    // Duplicate-invite check
    Optional<PendingFriendInvite> findByInviterIdAndInviteeEmail(Long inviterId, String inviteeEmail);
}

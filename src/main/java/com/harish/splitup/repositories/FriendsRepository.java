package com.harish.splitup.repositories;

import com.harish.splitup.entities.Friends;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface FriendsRepository extends JpaRepository<Friends,Long> {

    @Query("SELECT f FROM Friends f WHERE f.user.id = :userId OR f.friend.id = :userId")
    List<Friends> findAllByUserId(@Param("userId") long userId);

    @Query("SELECT f FROM Friends f WHERE (f.user.id = :userId AND f.friend.id = :friendId) " +
            "OR (f.user.id = :friendId AND f.friend.id = :userId)")
    Optional<Friends> findExisting(@Param("userId") long userId, @Param("friendId") long friendId);

}

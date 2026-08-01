package com.harish.splitup.repositories;

import com.harish.splitup.entities.Friends;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface FriendsRepository extends JpaRepository<Friends,Long> {

    @Query("SELECT f FROM Friends f WHERE f.user.id = :userId OR f.friend.id = :userId")
    List<Friends> findAllByUserId(@Param("userId") long userId);

}

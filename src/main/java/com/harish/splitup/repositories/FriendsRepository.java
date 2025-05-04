package com.harish.splitup.repositories;

import com.harish.splitup.entities.Friends;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface FriendsRepository extends JpaRepository<Friends,Long> {

    List<Friends> findAllByUserId(long userId);

}

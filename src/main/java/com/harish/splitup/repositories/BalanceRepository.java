package com.harish.splitup.repositories;

import com.harish.splitup.entities.Balance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface BalanceRepository  extends JpaRepository<Balance, Long> {

    List<Balance> findAllByUserId(long userId);

    List<Balance> findAllByUserIdAndGroupGroupId(long userId,long groupId);

    @Query("SELECT b FROM Balance b WHERE b.user.id = :userId AND b.friend.id IN :friendIds")
    List<Balance> findAllByUserIdAndFriendIds(@Param("userId") long userId, @Param("friendIds") List<Long> friendIds);

    @Query("SELECT b FROM Balance b WHERE b.user.id IN :userId AND b.friend.id = :friendIds")
    List<Balance> findAllByUserIdsAndFriendId(@Param("userIds") List<Long> userIds , @Param("friendId") long friendId);

}

package com.harish.splitup.repositories;

import com.harish.splitup.entities.Balance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BalanceRepository extends JpaRepository<Balance, Long> {

    List<Balance> findAllByUserId(long userId);

    List<Balance> findAllByUserIdAndGroupGroupId(long userId, long groupId);

    @Query("SELECT b FROM Balance b WHERE b.user.id = :userId AND b.friend.id IN :friendIds")
    List<Balance> findAllByUserIdAndFriendIds(@Param("userId") long userId, @Param("friendIds") List<Long> friendIds);

    @Query("SELECT b FROM Balance b WHERE b.user.id IN :userIds AND b.friend.id = :friendId")
    List<Balance> findAllByUserIdsAndFriendId(@Param("userIds") List<Long> userIds, @Param("friendId") long friendId);

    @Query("SELECT b FROM Balance b WHERE b.user.id = :userId AND b.friend.id IN :friendIds AND b.group.groupId = :groupId")
    List<Balance> findAllByUserIdAndFriendIdsAndGroupId(@Param("userId") long userId,
                                                        @Param("friendIds") List<Long> friendIds,
                                                        @Param("groupId") long groupId);

    @Query("SELECT b FROM Balance b WHERE b.user.id IN :userIds AND b.friend.id = :friendId AND b.group.groupId = :groupId")
    List<Balance> findAllByUserIdsAndFriendIdAndGroupId(@Param("userIds") List<Long> userIds,
                                                        @Param("friendId") long friendId,
                                                        @Param("groupId") long groupId);

    @Query("SELECT b FROM Balance b WHERE b.user.id = :userId AND b.friend.id IN :friendIds AND b.group IS NULL")
    List<Balance> findPersonalByUserIdAndFriendIds(@Param("userId") long userId, @Param("friendIds") List<Long> friendIds);

    @Query("SELECT b FROM Balance b WHERE b.user.id IN :userIds AND b.friend.id = :friendId AND b.group IS NULL")
    List<Balance> findPersonalByUserIdsAndFriendId(@Param("userIds") List<Long> userIds, @Param("friendId") long friendId);
}

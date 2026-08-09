package com.harish.splitup.repositories;

import com.harish.splitup.entities.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense,Long> {

    @Query("SELECT DISTINCT e FROM Expense e JOIN e.splitDetails sd WHERE sd.user.id = :userId AND e.trashed = false ORDER BY e.createdAt DESC")
    List<Expense> findAllByUserId(@Param("userId") Long userId);

    @Query(value = "SELECT e.* FROM expense e " +
    "JOIN split_details sd ON sd.expense_id = e.expense_id " +
    "WHERE sd.user_id IN (:userId, :friendId) AND e.trashed = false " +
    "GROUP BY e.expense_id HAVING COUNT(DISTINCT sd.user_id) = 2 " +
    "ORDER BY e.created_at DESC", nativeQuery = true)
    List<Expense> findAllExpenseByFriend(@Param("userId") long userId, @Param("friendId") long friendId);


}

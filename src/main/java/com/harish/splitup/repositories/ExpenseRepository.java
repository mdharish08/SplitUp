package com.harish.splitup.repositories;

import com.harish.splitup.entities.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense,Long> {

    @Query(value = "SELECT e.* FROM expense e JOIN split_details sd ON sd.expense_id = e.expense_id" +
    "WHERE sd.user_id IN (:userId, :friendId) AND e.group_id = 0" +
    "GROUP BY e.expense_id" , nativeQuery = true)
    List<Expense> findAllExpenseByFriend(@Param("userId") long userId,@Param("friendId") long friendId);


}

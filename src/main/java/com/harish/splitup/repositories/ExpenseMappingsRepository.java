package com.harish.splitup.repositories;

import com.harish.splitup.entities.Expense;
import com.harish.splitup.entities.ExpenseMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExpenseMappingsRepository extends JpaRepository<ExpenseMapping,Long> {

    @Query("SELECT m.expense FROM ExpenseMapping m WHERE m.user.id = :userId AND m.expense.trashed = false")
    List<Expense> findAllExpensesByUserId(@Param("userId") long userId);
}

package com.harish.splitup.repositories;

import com.harish.splitup.entities.ExpenseMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExpenseMappingsRepository extends JpaRepository<ExpenseMapping,Long> {
}

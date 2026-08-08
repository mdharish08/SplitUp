package com.harish.splitup.repositories;

import com.harish.splitup.entities.Comments;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CommentsRepository extends JpaRepository<Comments, Long> {

    List<Comments> findAllByExpenseExpenseIdOrderByCreatedAtAsc(Long expenseId);

    Optional<Comments> findByCommentIdAndExpenseExpenseId(Long commentId, Long expenseId);

    long countByExpenseExpenseId(Long expenseId);
}

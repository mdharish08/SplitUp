package com.harish.splitup.controllers;

import com.harish.splitup.dto.CreateExpenseCommentRequestDto;
import com.harish.splitup.dto.ExpenseCommentDto;
import com.harish.splitup.dto.ExpenseDto;
import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.service.ExpenseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("api/v1/expense")
@RequiredArgsConstructor
public class ExpenseController {

    private final ExpenseService expenseService;

    @GetMapping("/group/{groupId}")
    public ResponseEntity<ResponseDto<List<ExpenseDto>>> getGroupExpenses(@PathVariable Long groupId) {
        List<ExpenseDto> data = expenseService.getGroupExpenseDetails(groupId);
        return ResponseEntity.ok(ResponseDto.success(data));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ResponseDto<List<ExpenseDto>>> getUserExpenses(@PathVariable Long userId) {
        List<ExpenseDto> data = expenseService.getUserExpenses(userId);
        return ResponseEntity.ok(ResponseDto.success(data));
    }

    @GetMapping("/user/{userId}/friend/{friendId}")
    public ResponseEntity<ResponseDto<List<ExpenseDto>>> getFriendsExpenses(
            @PathVariable Long userId, @PathVariable Long friendId) {
        List<ExpenseDto> data = expenseService.getFriendExpenses(userId, friendId);
        return ResponseEntity.ok(ResponseDto.success(data));
    }

    @GetMapping("/{expenseId}")
    public ResponseEntity<ResponseDto<ExpenseDto>> getExpenseById(@PathVariable Long expenseId,
                                                                  Authentication authentication) {
        return ResponseEntity.ok(ResponseDto.success(expenseService.getExpenseById(expenseId, authentication.getName())));
    }

    @PostMapping
    public ResponseEntity<ResponseDto<ExpenseDto>> createExpense(@RequestBody ExpenseDto dto) {
        ExpenseDto created = expenseService.createExpense(dto);
        return ResponseEntity.status(201).body(ResponseDto.success(created));
    }

    @PutMapping("/{expenseId}")
    public ResponseEntity<ResponseDto<ExpenseDto>> updateExpense(
            @PathVariable Long expenseId,
            @RequestBody ExpenseDto dto,
            Authentication authentication) {
        ExpenseDto updated = expenseService.updateExpense(expenseId, dto, authentication.getName());
        return ResponseEntity.ok(ResponseDto.success(updated));
    }

    @DeleteMapping("/{expenseId}")
    public ResponseEntity<ResponseDto<Void>> deleteExpense(@PathVariable Long expenseId,
                                                           Authentication authentication) {
        expenseService.deleteExpense(expenseId, authentication.getName());
        return ResponseEntity.ok(ResponseDto.success(null));
    }

    @PatchMapping("/{expenseId}/restore")
    public ResponseEntity<ResponseDto<ExpenseDto>> restoreExpense(@PathVariable Long expenseId,
                                                                  Authentication authentication) {
        ExpenseDto restored = expenseService.restoreExpense(expenseId, authentication.getName());
        return ResponseEntity.ok(ResponseDto.success(restored));
    }

    @GetMapping("/{expenseId}/comments")
    public ResponseEntity<ResponseDto<List<ExpenseCommentDto>>> getExpenseComments(@PathVariable Long expenseId) {
        return ResponseEntity.ok(ResponseDto.success(expenseService.getExpenseComments(expenseId)));
    }

    @PostMapping("/{expenseId}/comments")
    public ResponseEntity<ResponseDto<ExpenseCommentDto>> addExpenseComment(
            @PathVariable Long expenseId,
            @RequestBody CreateExpenseCommentRequestDto req,
            Authentication authentication) {
        ExpenseCommentDto created = expenseService.addExpenseComment(expenseId, authentication.getName(), req);
        return ResponseEntity.status(201).body(ResponseDto.success(created));
    }

    @DeleteMapping("/{expenseId}/comments/{commentId}")
    public ResponseEntity<ResponseDto<Void>> deleteExpenseComment(
            @PathVariable Long expenseId,
            @PathVariable Long commentId,
            Authentication authentication) {
        expenseService.deleteExpenseComment(expenseId, commentId, authentication.getName());
        return ResponseEntity.ok(ResponseDto.success(null));
    }
}

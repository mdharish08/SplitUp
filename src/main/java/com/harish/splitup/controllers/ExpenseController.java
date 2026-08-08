package com.harish.splitup.controllers;

import com.harish.splitup.dto.ExpenseDto;
import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.service.ExpenseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.NoSuchElementException;

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

    @PostMapping
    public ResponseEntity<ResponseDto<ExpenseDto>> createExpense(@RequestBody ExpenseDto dto) {
        ExpenseDto created = expenseService.createExpense(dto);
        return ResponseEntity.status(201).body(ResponseDto.success(created));
    }
}

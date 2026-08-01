package com.harish.splitup.controllers;

import com.harish.splitup.dto.ExpenseDto;
import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.service.ExpenseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("api/v1/expense")
public class ExpenseController {

    @Autowired
    ExpenseService expenseService;

    @GetMapping("/group/{groupId}")
    public ResponseEntity<ResponseDto<List<ExpenseDto>>> getGroupExpenses(@PathVariable Long groupId) {
        try {
            List<ExpenseDto> data = expenseService.getGroupExpenseDetails(groupId);
            return ResponseEntity.ok(ResponseDto.success(data));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ResponseDto.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ResponseDto.error(e.getMessage()));
        }
    }

    @GetMapping("/user/{userId}/friend/{friendId}")
    public ResponseEntity<ResponseDto<List<ExpenseDto>>> getFriendsExpenses(
            @PathVariable Long userId, @PathVariable Long friendId) {
        try {
            List<ExpenseDto> data = expenseService.getFriendExpenses(userId, friendId);
            return ResponseEntity.ok(ResponseDto.success(data));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ResponseDto.error(e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ResponseDto.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ResponseDto.error(e.getMessage()));
        }
    }

    @PostMapping
    public ResponseEntity<ResponseDto<ExpenseDto>> createExpense(@RequestBody ExpenseDto dto) {
        try {
            ExpenseDto created = expenseService.createExpense(dto);
            return ResponseEntity.status(HttpStatus.CREATED).body(ResponseDto.success(created));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ResponseDto.error(e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ResponseDto.error(e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(ResponseDto.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ResponseDto.error(e.getMessage()));
        }
    }
}

package com.harish.splitup.controllers;

import com.harish.splitup.dto.ExpenseDto;
import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.service.ExpenseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("api/v1/expense")
public class ExpenseController {

    @Autowired
    ExpenseService expenseService;

    @GetMapping("/group/{groupId}")
    public ResponseEntity<ResponseDto<List<ExpenseDto>>> getGroupExpenses(@PathVariable Long groupId){
        ResponseDto<List<ExpenseDto>> responseDto = new ResponseDto<>();
        try{
            responseDto.setData(expenseService.getGroupExpenseDetails(groupId));
            responseDto.setCode(0);
            responseDto.setMessage("success");
            return new ResponseEntity<>(responseDto, HttpStatus.OK);
        }catch (Exception e){
            responseDto.setCode(1);
            responseDto.setMessage("failed");
            return new ResponseEntity<>(responseDto, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("user/{userId}/friend/{friendId}")
    public ResponseEntity<ResponseDto<List<ExpenseDto>>> getFriendsExpenses(@PathVariable Long userId,@PathVariable Long friendId){
        ResponseDto<List<ExpenseDto>> responseDto = new ResponseDto<>();
        try{
            responseDto.setData(expenseService.getFriendExpenses(userId,friendId));
            responseDto.setCode(0);
            responseDto.setMessage("success");
            return new ResponseEntity<>(responseDto, HttpStatus.OK);
        }catch (Exception e){
            responseDto.setCode(1);
            responseDto.setMessage("failed");
            return new ResponseEntity<>(responseDto, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping
    public ResponseEntity<ResponseDto<ExpenseDto>> createExpense(@RequestBody ExpenseDto dto){
        ResponseDto<ExpenseDto> responseDto = new ResponseDto<>();
        try{
            responseDto.setData(expenseService.createExpense(dto));
            responseDto.setCode(0);
            responseDto.setMessage("success");
            return new ResponseEntity<>(responseDto, HttpStatus.OK);
        }catch (Exception e){
            responseDto.setCode(1);
            responseDto.setMessage("failed");
            return new ResponseEntity<>(responseDto, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

}

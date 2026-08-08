package com.harish.splitup.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.harish.splitup.controllers.ExpenseController;
import com.harish.splitup.dto.CategoryDto;
import com.harish.splitup.dto.ExpenseDto;
import com.harish.splitup.exception.ExpenseValidationException;
import com.harish.splitup.repositories.CategoryRepository;
import com.harish.splitup.repositories.UserRepository;
import com.harish.splitup.service.ExpenseService;
import com.harish.splitup.service.JwtService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.NoSuchElementException;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(ExpenseController.class)
@WithMockUser
class ExpenseControllerTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;

    // AppConfig dependencies
    @MockBean JwtService jwtService;
    @MockBean UserRepository userRepository;
    @MockBean CategoryRepository categoryRepository;

    // Controller dependency
    @MockBean ExpenseService expenseService;

    private ExpenseDto sampleExpenseDto() {
        CategoryDto cat = new CategoryDto();
        cat.setCategoryId(1L);
        cat.setCategoryName("Food");

        ExpenseDto dto = new ExpenseDto();
        dto.setExpenseId(10L);
        dto.setCategory(cat);
        dto.setCost(new BigDecimal("100.00"));
        dto.setCurrencyCode("USD");
        dto.setExpenseType("EXPENSE");
        dto.setDescription("Lunch");
        return dto;
    }

    // ── POST /api/v1/expense ──────────────────────────────────────────────────

    @Test
    void createExpense_success_returns201() throws Exception {
        ExpenseDto response = sampleExpenseDto();
        given(expenseService.createExpense(any(ExpenseDto.class))).willReturn(response);

        mockMvc.perform(post("/api/v1/expense")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleExpenseDto())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.expenseId").value(10));
    }

    @Test
    void createExpense_illegalArgument_returns400() throws Exception {
        given(expenseService.createExpense(any(ExpenseDto.class)))
                .willThrow(new IllegalArgumentException("Category is required"));

        mockMvc.perform(post("/api/v1/expense")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleExpenseDto())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Category is required"));
    }

    @Test
    void createExpense_noSuchElement_returns404() throws Exception {
        given(expenseService.createExpense(any(ExpenseDto.class)))
                .willThrow(new NoSuchElementException("Category not found"));

        mockMvc.perform(post("/api/v1/expense")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleExpenseDto())))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Category not found"));
    }

    @Test
    void createExpense_validationError_returns422() throws Exception {
        given(expenseService.createExpense(any(ExpenseDto.class)))
                .willThrow(new ExpenseValidationException("No payer found"));

        mockMvc.perform(post("/api/v1/expense")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleExpenseDto())))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error").value("No payer found"));
    }

    // ── GET /api/v1/expense/user/{userId} ─────────────────────────────────────

    @Test
    void getUserExpenses_success_returns200() throws Exception {
        given(expenseService.getUserExpenses(1L)).willReturn(List.of(sampleExpenseDto()));

        mockMvc.perform(get("/api/v1/expense/user/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].expenseId").value(10));
    }

    // ── GET /api/v1/expense/group/{groupId} ───────────────────────────────────

    @Test
    void getGroupExpenses_success_returns200() throws Exception {
        given(expenseService.getGroupExpenseDetails(5L)).willReturn(List.of(sampleExpenseDto()));

        mockMvc.perform(get("/api/v1/expense/group/5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void getGroupExpenses_notFound_returns404() throws Exception {
        given(expenseService.getGroupExpenseDetails(999L))
                .willThrow(new NoSuchElementException("Group not found"));

        mockMvc.perform(get("/api/v1/expense/group/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Group not found"));
    }

    // ── GET /api/v1/expense/user/{userId}/friend/{friendId} ───────────────────

    @Test
    void getFriendExpenses_success_returns200() throws Exception {
        given(expenseService.getFriendExpenses(1L, 2L)).willReturn(List.of(sampleExpenseDto()));

        mockMvc.perform(get("/api/v1/expense/user/1/friend/2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }
}

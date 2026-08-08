package com.harish.splitup.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.harish.splitup.controllers.ExpenseController;
import com.harish.splitup.dto.CategoryDto;
import com.harish.splitup.dto.CreateExpenseCommentRequestDto;
import com.harish.splitup.dto.ExpenseCommentDto;
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
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(ExpenseController.class)
@WithMockUser(username = "alice@example.com")
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
        dto.setId(10L);
        dto.setCategory(cat);
        dto.setCost(new BigDecimal("100.00"));
        dto.setCurrencyCode("USD");
        dto.setExpenseType("EXPENSE");
        dto.setDescription("Lunch");
        return dto;
    }

    // ── GET /api/v1/expense/{expenseId} ──────────────────────────────────────

    @Test
    void getExpenseById_success_returns200() throws Exception {
        given(expenseService.getExpenseById(10L)).willReturn(sampleExpenseDto());

        mockMvc.perform(get("/api/v1/expense/10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(10));
    }

    @Test
    void getExpenseById_notFound_returns404() throws Exception {
        given(expenseService.getExpenseById(999L))
                .willThrow(new NoSuchElementException("Expense not found: 999"));

        mockMvc.perform(get("/api/v1/expense/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Expense not found: 999"));
    }

    // ── PUT /api/v1/expense/{expenseId} ───────────────────────────────────────

    @Test
    void updateExpense_success_returns200() throws Exception {
        ExpenseDto updated = sampleExpenseDto();
        updated.setDescription("Updated lunch");
        given(expenseService.updateExpense(eq(10L), any(ExpenseDto.class))).willReturn(updated);

        mockMvc.perform(put("/api/v1/expense/10")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleExpenseDto())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.description").value("Updated lunch"));
    }

    @Test
    void updateExpense_notFound_returns404() throws Exception {
        given(expenseService.updateExpense(eq(999L), any(ExpenseDto.class)))
                .willThrow(new NoSuchElementException("Expense not found: 999"));

        mockMvc.perform(put("/api/v1/expense/999")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleExpenseDto())))
                .andExpect(status().isNotFound());
    }

    // ── DELETE /api/v1/expense/{expenseId} ────────────────────────────────────

    @Test
    void deleteExpense_success_returns200() throws Exception {
        mockMvc.perform(delete("/api/v1/expense/10")
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("success"));
    }

    @Test
    void deleteExpense_notFound_returns404() throws Exception {
        org.mockito.Mockito.doThrow(new NoSuchElementException("Expense not found: 999"))
                .when(expenseService).deleteExpense(999L);

        mockMvc.perform(delete("/api/v1/expense/999")
                        .with(csrf()))
                .andExpect(status().isNotFound());
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
                .andExpect(jsonPath("$.data.id").value(10));
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
                .andExpect(jsonPath("$.data[0].id").value(10));
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

    @Test
    void getExpenseComments_success_returns200() throws Exception {
        ExpenseCommentDto comment = new ExpenseCommentDto();
        comment.setCommentId(1L);
        comment.setContent("Looks good");
        comment.setAddedByEmail("alice@example.com");
        given(expenseService.getExpenseComments(10L)).willReturn(List.of(comment));

        mockMvc.perform(get("/api/v1/expense/10/comments"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].content").value("Looks good"));
    }

    @Test
    void addExpenseComment_success_returns201() throws Exception {
        ExpenseCommentDto comment = new ExpenseCommentDto();
        comment.setCommentId(1L);
        comment.setContent("Looks good");
        comment.setAddedByEmail("alice@example.com");
        CreateExpenseCommentRequestDto req = new CreateExpenseCommentRequestDto();
        req.setContent("Looks good");
        given(expenseService.addExpenseComment(eq(10L), eq("alice@example.com"), any(CreateExpenseCommentRequestDto.class)))
                .willReturn(comment);

        mockMvc.perform(post("/api/v1/expense/10/comments")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.content").value("Looks good"));
    }

    @Test
    void deleteExpenseComment_success_returns200() throws Exception {
        mockMvc.perform(delete("/api/v1/expense/10/comments/1")
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("success"));
    }
}

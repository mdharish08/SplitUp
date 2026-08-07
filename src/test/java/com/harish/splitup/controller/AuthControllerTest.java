package com.harish.splitup.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.harish.splitup.controllers.AuthController;
import com.harish.splitup.dto.SignupRequestDto;
import com.harish.splitup.dto.UserDto;
import com.harish.splitup.repositories.CategoryRepository;
import com.harish.splitup.repositories.UserRepository;
import com.harish.splitup.service.JwtService;
import com.harish.splitup.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.springframework.security.test.context.support.WithMockUser;

@WebMvcTest(AuthController.class)
@WithMockUser
class AuthControllerTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;

    // AppConfig dependencies
    @MockBean JwtService jwtService;
    @MockBean UserRepository userRepository;
    @MockBean CategoryRepository categoryRepository;

    // Controller dependency
    @MockBean UserService userService;

    private SignupRequestDto validRequest() {
        SignupRequestDto req = new SignupRequestDto();
        req.setFirstName("Alice");
        req.setLastName("Smith");
        req.setEmailId("alice@example.com");
        req.setPassword("securePass1!");
        return req;
    }

    private UserDto sampleUserDto() {
        UserDto dto = new UserDto();
        dto.setId(1L);
        dto.setFirstName("Alice");
        dto.setLastName("Smith");
        dto.setEmailId("alice@example.com");
        dto.setRegistrationStatus("not_verified");
        return dto;
    }

    // ── POST /api/v1/signup ───────────────────────────────────────────────────

    @Test
    void signup_success_returns201() throws Exception {
        given(userService.registerUser(any(SignupRequestDto.class))).willReturn(sampleUserDto());

        mockMvc.perform(post("/api/v1/signup")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.message").value("success"))
                .andExpect(jsonPath("$.data.emailId").value("alice@example.com"));
    }

    @Test
    void signup_duplicateEmail_returns409() throws Exception {
        given(userService.registerUser(any(SignupRequestDto.class)))
                .willThrow(new IllegalStateException("Email already registered: alice@example.com"));

        mockMvc.perform(post("/api/v1/signup")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest())))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("Email already registered: alice@example.com"));
    }

    @Test
    void signup_badInput_returns400() throws Exception {
        given(userService.registerUser(any(SignupRequestDto.class)))
                .willThrow(new IllegalArgumentException("Email is required"));

        SignupRequestDto bad = new SignupRequestDto();
        bad.setFirstName("Alice");
        // missing email and password

        mockMvc.perform(post("/api/v1/signup")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(bad)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Email is required"));
    }
}

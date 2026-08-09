package com.harish.splitup.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.controllers.UserController;
import com.harish.splitup.dto.AddFriendRequestDto;
import com.harish.splitup.dto.FriendsDto;
import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.repositories.CategoryRepository;
import com.harish.splitup.repositories.UserRepository;
import com.harish.splitup.service.JwtService;
import com.harish.splitup.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;

    // AppConfig dependencies
    @MockBean JwtService jwtService;
    @MockBean UserRepository userRepository;
    @MockBean CategoryRepository categoryRepository;

    // Controller dependency
    @MockBean UserService userService;

    private UsernamePasswordAuthenticationToken authFor(long userId, String email) {
        SplitUser principal = SplitUser.builder()
                .withId(userId)
                .withEmailId(email)
                .withAccountStatus(AppConstants.AccountStatus.ACTIVE)
                .build();
        return new UsernamePasswordAuthenticationToken(principal, null, List.of());
    }

    private FriendsDto registeredFriend() {
        FriendsDto dto = new FriendsDto();
        dto.setId(2L);
        dto.setFirstName("Bob");
        dto.setLastName("Jones");
        dto.setEmailId("bob@example.com");
        dto.setRegistrationStatus("not_verified");
        dto.setGroups(new ArrayList<>());
        return dto;
    }

    private FriendsDto pendingFriend(String email) {
        FriendsDto dto = new FriendsDto();
        dto.setEmailId(email);
        dto.setFirstName(email);
        dto.setRegistrationStatus("pending");
        dto.setGroups(new ArrayList<>());
        return dto;
    }

    private AddFriendRequestDto addFriendRequest(String email) {
        AddFriendRequestDto req = new AddFriendRequestDto();
        req.setEmailId(email);
        req.setCurrencyCode("USD");
        return req;
    }

    // ── GET /api/v1/friends/{userId} ─────────────────────────────────────────

    @Test
    void getFriendsMeta_success_returns200() throws Exception {
        given(userService.getFriendsMeta(1L)).willReturn(List.of(registeredFriend()));

        mockMvc.perform(get("/api/v1/friends/1")
                        .with(authentication(authFor(1L, "alice@example.com"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].emailId").value("bob@example.com"));
    }

    // ── POST /api/v1/friends/{userId} ────────────────────────────────────────

    @Test
    void addFriend_registeredUser_returns201() throws Exception {
        given(userService.addFriend(eq(1L), any(AddFriendRequestDto.class)))
                .willReturn(registeredFriend());

        mockMvc.perform(post("/api/v1/friends/1")
                        .with(authentication(authFor(1L, "alice@example.com")))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(addFriendRequest("bob@example.com"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.registrationStatus").value("not_verified"));
    }

    @Test
    void addFriend_pendingInvite_returns201WithPendingStatus() throws Exception {
        given(userService.addFriend(eq(1L), any(AddFriendRequestDto.class)))
                .willReturn(pendingFriend("stranger@example.com"));

        mockMvc.perform(post("/api/v1/friends/1")
                        .with(authentication(authFor(1L, "alice@example.com")))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(addFriendRequest("stranger@example.com"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.registrationStatus").value("pending"));
    }

    @Test
    void addFriend_alreadyFriends_returns409() throws Exception {
        given(userService.addFriend(eq(1L), any(AddFriendRequestDto.class)))
                .willThrow(new IllegalStateException("already friends"));

        mockMvc.perform(post("/api/v1/friends/1")
                        .with(authentication(authFor(1L, "alice@example.com")))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(addFriendRequest("bob@example.com"))))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("already friends"));
    }

    @Test
    void addFriend_selfAdd_returns400() throws Exception {
        given(userService.addFriend(eq(1L), any(AddFriendRequestDto.class)))
                .willThrow(new IllegalArgumentException("You cannot add yourself as a friend"));

        mockMvc.perform(post("/api/v1/friends/1")
                        .with(authentication(authFor(1L, "alice@example.com")))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(addFriendRequest("alice@example.com"))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("You cannot add yourself as a friend"));
    }

    @Test
    void getFriendsMeta_userIdMismatch_returns403() throws Exception {
        mockMvc.perform(get("/api/v1/friends/99")
                        .with(authentication(authFor(1L, "alice@example.com"))))
                .andExpect(status().isForbidden());
    }
}

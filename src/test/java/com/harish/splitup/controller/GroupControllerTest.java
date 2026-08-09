package com.harish.splitup.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.controllers.GroupController;
import com.harish.splitup.dto.CreateGroupRequestDto;
import com.harish.splitup.dto.GroupMetaResponseDto;
import com.harish.splitup.repositories.CategoryRepository;
import com.harish.splitup.repositories.UserRepository;
import com.harish.splitup.service.GroupService;
import com.harish.splitup.service.JwtService;
import com.harish.splitup.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(GroupController.class)
@WithMockUser
class GroupControllerTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;

    // AppConfig dependencies
    @MockBean JwtService jwtService;
    @MockBean UserRepository userRepository;
    @MockBean CategoryRepository categoryRepository;

    // Controller dependencies
    @MockBean GroupService groupService;
    @MockBean UserService userService;

    private GroupMetaResponseDto buildGroupResponse() {
        return new GroupMetaResponseDto(
                1L,
                "Trip to Goa",
                AppConstants.GroupType.TRIP,
                AppConstants.CurrencyCode.USD,
                "Fun trip",
                null,
                null,
                List.of(new GroupMetaResponseDto.GroupMemberResponseDto(
                        2L,
                        "bob@example.com",
                        "Bob",
                        "Jones",
                        "not_verified",
                        null
                ))
        );
    }

    private CreateGroupRequestDto requestMeta() {
        return new CreateGroupRequestDto(
                "Trip to Goa",
                AppConstants.GroupType.TRIP,
                AppConstants.CurrencyCode.USD,
                "Fun trip",
                List.of(new CreateGroupRequestDto.GroupMemberRequestDto(2L))
        );
    }

    // ── POST /api/v1/user/{userId}/group ─────────────────────────────────────

    @Test
    void createGroup_success_returns201() throws Exception {
        given(groupService.createGroup(eq(1L), any(CreateGroupRequestDto.class)))
                .willReturn(buildGroupResponse());

        mockMvc.perform(post("/api/v1/user/1/group")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestMeta())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name").value("Trip to Goa"))
                .andExpect(jsonPath("$.data.id").value(1));
    }

    @Test
    void createGroup_missingName_returns400() throws Exception {
        given(groupService.createGroup(eq(1L), any(CreateGroupRequestDto.class)))
                .willThrow(new IllegalArgumentException("Group name is required"));

        CreateGroupRequestDto bad = new CreateGroupRequestDto(
                null,
                AppConstants.GroupType.TRIP,
                AppConstants.CurrencyCode.USD,
                "Fun trip",
                List.of(new CreateGroupRequestDto.GroupMemberRequestDto(2L))
        );

        mockMvc.perform(post("/api/v1/user/1/group")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(bad)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Group name is required"));
    }

    // ── GET /api/v1/user/{userId}/group ──────────────────────────────────────

    @Test
    void getUserGroups_success_returns200() throws Exception {
        given(userService.getUserGroupMeta(1L)).willReturn(List.of(buildGroupResponse()));

        mockMvc.perform(get("/api/v1/user/1/group"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].name").value("Trip to Goa"));
    }
}

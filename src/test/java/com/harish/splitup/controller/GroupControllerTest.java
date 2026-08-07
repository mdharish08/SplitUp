package com.harish.splitup.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.harish.splitup.controllers.GroupController;
import com.harish.splitup.dto.UserGroupMeta;
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

import java.util.ArrayList;
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

    private UserGroupMeta buildGroupMeta() {
        UserGroupMeta meta = new UserGroupMeta();
        meta.setId(1L);
        meta.setName("Trip to Goa");
        meta.setGroupType("TRIP");
        meta.setCurrencyCode("USD");
        meta.setDescription("Fun trip");

        UserGroupMeta.GroupMemberMeta member = new UserGroupMeta.GroupMemberMeta();
        member.setId(2L);
        member.setEmail("bob@example.com");
        member.setFirstName("Bob");
        member.setLastName("Jones");
        member.setRegistrationStatus("not_verified");
        meta.setMembers(List.of(member));
        return meta;
    }

    private UserGroupMeta requestMeta() {
        UserGroupMeta meta = new UserGroupMeta();
        meta.setName("Trip to Goa");
        meta.setGroupType("TRIP");
        meta.setCurrencyCode("USD");
        meta.setDescription("Fun trip");

        UserGroupMeta.GroupMemberMeta member = new UserGroupMeta.GroupMemberMeta();
        member.setId(2L);
        meta.setMembers(new ArrayList<>(List.of(member)));
        return meta;
    }

    // ── POST /api/v1/user/{userId}/group ─────────────────────────────────────

    @Test
    void createGroup_success_returns201() throws Exception {
        given(groupService.createGroup(eq(1L), any(UserGroupMeta.class)))
                .willReturn(buildGroupMeta());

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
        given(groupService.createGroup(eq(1L), any(UserGroupMeta.class)))
                .willThrow(new IllegalArgumentException("Group name is required"));

        UserGroupMeta bad = requestMeta();
        bad.setName(null);

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
        given(userService.getUserGroupMeta(1L)).willReturn(List.of(buildGroupMeta()));

        mockMvc.perform(get("/api/v1/user/1/group"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].name").value("Trip to Goa"));
    }
}

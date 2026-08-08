package com.harish.splitup.controllers;

import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.dto.UserGroupMeta;
import com.harish.splitup.service.GroupService;
import com.harish.splitup.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/v1/user/{userId}/group")
@RequiredArgsConstructor
public class GroupController {

    private final GroupService groupService;
    private final UserService userService;

    @GetMapping
    public ResponseEntity<ResponseDto<List<UserGroupMeta>>> getUserGroups(@PathVariable Long userId) {
        return ResponseEntity.ok(ResponseDto.success(userService.getUserGroupMeta(userId)));
    }

    @PostMapping
    public ResponseEntity<ResponseDto<UserGroupMeta>> createGroup(
            @PathVariable Long userId, @RequestBody UserGroupMeta groupMeta) {
        UserGroupMeta created = groupService.createGroup(userId, groupMeta);
        return ResponseEntity.status(201).body(ResponseDto.success(created));
    }
}

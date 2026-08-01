package com.harish.splitup.controllers;

import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.dto.UserGroupMeta;
import com.harish.splitup.service.GroupService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/v1/user/{userId}/group")
public class GroupController {

    @Autowired
    GroupService groupService;

    @PostMapping
    public ResponseEntity<ResponseDto<UserGroupMeta>> createGroup(
            @PathVariable Long userId, @RequestBody UserGroupMeta groupMeta) {
        try {
            UserGroupMeta created = groupService.createGroup(userId, groupMeta);
            return ResponseEntity.status(HttpStatus.CREATED).body(ResponseDto.success(created));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ResponseDto.error(e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ResponseDto.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ResponseDto.error(e.getMessage()));
        }
    }
}

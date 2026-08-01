package com.harish.splitup.controllers;

import com.harish.splitup.dto.FriendsDto;
import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/v1/friends")
public class UserController {

    @Autowired
    UserService userService;

    @GetMapping("/{userId}")
    public ResponseEntity<ResponseDto<List<FriendsDto>>> getFriendsMeta(@PathVariable long userId) {
        try {
            List<FriendsDto> data = userService.getFriendsMeta(userId);
            return ResponseEntity.ok(ResponseDto.success(data));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ResponseDto.error(e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ResponseDto.error(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ResponseDto.error(e.getMessage()));
        }
    }
}

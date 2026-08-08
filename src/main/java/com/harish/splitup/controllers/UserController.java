package com.harish.splitup.controllers;

import com.harish.splitup.dto.AddFriendRequestDto;
import com.harish.splitup.dto.FriendsDto;
import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/v1/friends")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{userId}")
    public ResponseEntity<ResponseDto<List<FriendsDto>>> getFriendsMeta(@PathVariable long userId) {
        List<FriendsDto> data = userService.getFriendsMeta(userId);
        return ResponseEntity.ok(ResponseDto.success(data));
    }

    @PostMapping("/{userId}")
    public ResponseEntity<ResponseDto<FriendsDto>> addFriend(@PathVariable long userId,
                                                              @RequestBody AddFriendRequestDto req) {
        FriendsDto data = userService.addFriend(userId, req);
        return ResponseEntity.status(201).body(ResponseDto.success(data));
    }
}

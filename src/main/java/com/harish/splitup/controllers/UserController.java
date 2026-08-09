package com.harish.splitup.controllers;

import com.harish.splitup.dto.AddFriendRequestDto;
import com.harish.splitup.dto.FriendsDto;
import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/v1/friends")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{userId}")
    public ResponseEntity<ResponseDto<List<FriendsDto>>> getFriendsMeta(@PathVariable long userId,
                                                                         Authentication authentication) {
        validateOwnership(userId, authentication);
        List<FriendsDto> data = userService.getFriendsMeta(userId);
        return ResponseEntity.ok(ResponseDto.success(data));
    }

    @PostMapping("/{userId}")
    public ResponseEntity<ResponseDto<FriendsDto>> addFriend(@PathVariable long userId,
                                                              @RequestBody AddFriendRequestDto req,
                                                              Authentication authentication) {
        validateOwnership(userId, authentication);
        FriendsDto data = userService.addFriend(userId, req);
        return ResponseEntity.status(201).body(ResponseDto.success(data));
    }

    private void validateOwnership(long userId, Authentication authentication) {
        if (authentication == null || !(authentication.getPrincipal() instanceof SplitUser principal)) {
            throw new AccessDeniedException("Unauthorized user context");
        }
        if (principal.getId() == null || principal.getId() != userId) {
            throw new AccessDeniedException("You can only access your own friends data");
        }
    }
}

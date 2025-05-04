package com.harish.splitup.controllers;

import com.harish.splitup.dto.*;
import com.harish.splitup.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("api/v1/friends")
public class UserController {

    @Autowired
    UserService userService;

    @GetMapping("/{userId}")
    public ResponseEntity<ResponseDto<List<FriendsDto>>> getFriendsMeta(@PathVariable long userId){
        ResponseDto<List<FriendsDto>> responseDto = new ResponseDto<>();
        try{
            responseDto.setData(this.userService.getFriendsMeta(userId));
            responseDto.setCode(0);
            responseDto.setMessage("success");
            return new ResponseEntity<>(responseDto, HttpStatus.OK);
        }catch (Exception e){
            responseDto.setCode(1);
            responseDto.setMessage("failed");
            return new ResponseEntity<>(responseDto, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}

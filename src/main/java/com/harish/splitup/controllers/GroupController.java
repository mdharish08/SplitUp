package com.harish.splitup.controllers;

import com.harish.splitup.dto.ResponseDto;
import com.harish.splitup.dto.UserGroupMeta;
import com.harish.splitup.service.GroupService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/user/{userId}/group" )
public class GroupController {

    @Autowired
    GroupService groupService;

    @PostMapping
    public ResponseEntity<ResponseDto<UserGroupMeta>> createGroup(@PathVariable Long userId, @RequestBody UserGroupMeta groupMeta) {
        ResponseDto<UserGroupMeta> response = new ResponseDto<>();
        try{
            response.setData(groupService.createGroup(userId,groupMeta));
            response.setCode(0);
            response.setMessage("success");
            return new ResponseEntity<>(response, HttpStatus.OK);
        }catch (Exception e){
            response.setCode(0);
            response.setMessage("error");
            response.setError(e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

}

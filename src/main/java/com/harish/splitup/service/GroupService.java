package com.harish.splitup.service;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.UserGroupMeta;
import com.harish.splitup.entities.Balance;
import com.harish.splitup.entities.Group;
import com.harish.splitup.entities.GroupMapping;
import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.repositories.BalanceRepository;
import com.harish.splitup.repositories.GroupMappingRepository;
import com.harish.splitup.repositories.GroupRepository;
import com.harish.splitup.repositories.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
public class GroupService {

    @Autowired
    GroupRepository groupRepository;

    @Autowired
    UserRepository userRepository;

    @Autowired
    GroupMappingRepository groupMappingRepository;

    @Autowired
    BalanceRepository balanceRepository;

    @Transactional
    public UserGroupMeta createGroup(Long userId,UserGroupMeta groupMeta){
        if(groupMeta == null || groupMeta.getName() == null || groupMeta.getName().isEmpty()){
            throw new IllegalArgumentException("Group name is not found");
        }

        /*
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        SplitUser currentUser = (SplitUser) authentication.getPrincipal();
         */

        Group group = Group.builder()
                .withGroupName(groupMeta.getName())
                .withGroupType(AppConstants.GroupType.valueOf(groupMeta.getGroupType()))
                .withCreatedBy(userId)
                .withGroupDescription(groupMeta.getDescription())
                .withCreatedAt(Timestamp.from(Instant.now()))
                .withUpdatedAt(Timestamp.from(Instant.now()))
                .build();
        this.groupRepository.save(group);

        List<Long> groupMembers = new ArrayList<>();
        for(UserGroupMeta.GroupMemberMeta member : groupMeta.getMembers()){
            if(member.getId() != null){
                groupMembers.add(member.getId());
            }else{
                throw new IllegalArgumentException("Member id not found");
            }
        }
        List<SplitUser> groupMembersObj = this.userRepository.findAllById(groupMembers);
        if(groupMembersObj.size() != groupMembers.size()){
            throw new IllegalArgumentException("Some of the mebers are not found in the record");
        }
        List<GroupMapping> groupMapping = new ArrayList<>();
        for(SplitUser member : groupMembersObj){
            GroupMapping mapping = GroupMapping.builder()
                    .withGroupId(group.getGroupId())
                    .withMemberId(member.getId()).build();
            groupMapping.add(mapping);
        }
        this.groupMappingRepository.saveAll(groupMapping);

        List<Balance> balances = new ArrayList<>();
        for(SplitUser member : groupMembersObj){
           for(SplitUser friend : groupMembersObj){
               if(!member.equals(friend)){
                   Balance balance = Balance.builder()
                           .withGroup(group)
                           .withAmount(0.0)
                           .withUser(member)
                           .withFriend(friend)
                           .withCurrencyCode(group.getCurrencyCode())
                           .build();
                   balances.add(balance);
               }
           }
        }
        this.balanceRepository.saveAll(balances);

        List<UserGroupMeta.GroupMemberMeta> membersMeta = new ArrayList<>();
        for(SplitUser member : groupMembersObj){
            UserGroupMeta.GroupMemberMeta memberMeta = new UserGroupMeta.GroupMemberMeta();
            memberMeta.setId(member.getId());
            memberMeta.setEmail(member.getEmailId());
            memberMeta.setFirstName(member.getFirstName());
            memberMeta.setLastName(member.getLastName());
            memberMeta.setRegistrationStatus(memberMeta.getRegistrationStatus());
            membersMeta.add(memberMeta);
        }
        groupMeta.setMembers(membersMeta);
        groupMeta.setId(group.getGroupId());
        groupMeta.setCreatedAt(group.getCreatedAt());
        groupMeta.setUpdatedAt(group.getUpdatedAt());

        return groupMeta;
    }
}

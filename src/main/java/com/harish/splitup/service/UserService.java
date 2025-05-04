package com.harish.splitup.service;

import com.harish.splitup.dto.FriendsDto;
import com.harish.splitup.dto.UserGroupMeta;
import com.harish.splitup.entities.*;
import com.harish.splitup.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class UserService {

    @Autowired
    private FriendsRepository friendsRepository;

    @Autowired
    private BalanceRepository balanceRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private GroupMappingRepository groupMappingRepository;

    @Autowired
    private GroupRepository groupRepository;

    public List<UserGroupMeta> getUserGroupMeta(long userId){
        List<UserGroupMeta> result = new ArrayList<>();
        List<Long> userGroupIds = this.groupMappingRepository.findAllByMemberId(userId).stream().map(GroupMapping::getGroupId).toList();
        List<Group> userGroups = this.groupRepository.findAllById(userGroupIds);
        for(Group group : userGroups){
            List<GroupMapping> groupMembers = this.groupMappingRepository.findAllByGroupId(group.getGroupId());
            List<Long> allMembersId = groupMembers.stream().map(GroupMapping::getMemberId).toList();
            List<SplitUser> membersMeta = this.userRepository.findAllById(allMembersId);
            Map<Long,Balance> userIdVsBalance = new HashMap<>();
            this.balanceRepository.findAllByUserIdAndGroupGroupId(userId,group.getGroupId())
                    .forEach(balance ->  userIdVsBalance.put(balance.getFriend().getId(),balance));
            List<UserGroupMeta.GroupMemberMeta> membersBalance = new ArrayList<>();
            for(SplitUser member : membersMeta){
                UserGroupMeta.GroupMemberMeta memberMeta = new UserGroupMeta.GroupMemberMeta();
                memberMeta.setId(member.getId());
                memberMeta.setEmail(member.getEmailId());
                memberMeta.setFirstName(member.getFirstName());
                memberMeta.setLastName(member.getLastName());
                memberMeta.setRegistrationStatus(memberMeta.getRegistrationStatus());

                Balance memberGroupBalance = userIdVsBalance.get(member.getId());
                memberMeta.setBalance(memberGroupBalance.balanceDto());
                membersBalance.add(memberMeta);
            }
            UserGroupMeta groupMeta = new UserGroupMeta();
            groupMeta.setId(group.getGroupId());
            groupMeta.setName(group.getGroupName());
            groupMeta.setCreatedAt(group.getCreatedAt());
            groupMeta.setUpdatedAt(group.getUpdatedAt());
            groupMeta.setGroupType(group.getGroupType().name());
            groupMeta.setMembers(membersBalance);
            result.add(groupMeta);
        }
        return result;
    }

    public List<FriendsDto> getFriendsMeta(long userId){
        List<FriendsDto> result = new ArrayList<>();
        List<Friends> friendsList = friendsRepository.findAllByUserId(userId);
        List<Balance> userBalance = balanceRepository.findAllByUserId(userId);
        Map<Long,Balance> friendVsBalance = new HashMap<>();
        Map<Long,List<Balance>> friendVsGroupBalance = new HashMap<>();

        for(Balance balance : userBalance){
            if(balance.getGroup().getGroupId() == 0){
                friendVsBalance.put(balance.getFriend().getId() , balance);
            }else{
                friendVsGroupBalance.putIfAbsent(balance.getFriend().getId(),new ArrayList<>());
                friendVsGroupBalance.get(balance.getFriend().getId()).add(balance);
            }
        }

        for(Friends friend : friendsList){
            FriendsDto dto = new FriendsDto();
            SplitUser friendMeta = friend.getFriend();
            if(friendMeta != null){
                dto.setId(friendMeta.getId());
                dto.setLastName(friendMeta.getLastName());
                dto.setFirstName(friendMeta.getFirstName());
                dto.setUserName(friendMeta.getUsername());
                dto.setRegistrationStatus(friendMeta.isEmailVerified() ? "verified" : "not_verified");
                dto.setEmailId(friendMeta.getEmailId());
                Balance balance = friendVsBalance.get(friendMeta.getId());
                dto.setBalanceDto(balance.balanceDto());
                List<FriendsDto.FriendsGroupDto> groupBalances = new ArrayList<>();
                for(Balance groupBalance : friendVsGroupBalance.get(friend.getFriend().getId())){
                    FriendsDto.FriendsGroupDto friendGroupDto = new FriendsDto.FriendsGroupDto();
                    friendGroupDto.setBalanceDto(groupBalance.balanceDto());
                    friendGroupDto.setGroupId(groupBalance.getGroup().getGroupId());
                    groupBalances.add(friendGroupDto);
                }
                dto.setGroups(groupBalances);
            }
            result.add(dto);
        }
        return result;
    }
}

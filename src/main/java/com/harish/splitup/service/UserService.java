package com.harish.splitup.service;

import com.harish.splitup.dto.FriendsDto;
import com.harish.splitup.dto.UserGroupMeta;
import com.harish.splitup.entities.*;
import com.harish.splitup.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    @Transactional(readOnly = true)
    public List<UserGroupMeta> getUserGroupMeta(long userId) {
        List<UserGroupMeta> result = new ArrayList<>();
        List<Long> userGroupIds = groupMappingRepository.findAllByMemberId(userId)
                .stream().map(gm -> gm.getGroup().getGroupId()).toList();
        List<Group> userGroups = groupRepository.findAllById(userGroupIds);

        for (Group group : userGroups) {
            List<GroupMapping> groupMembers = groupMappingRepository.findAllByGroupGroupId(group.getGroupId());
            List<Long> allMemberIds = groupMembers.stream().map(gm -> gm.getMember().getId()).toList();
            List<SplitUser> membersMeta = userRepository.findAllById(allMemberIds);

            Map<Long, Balance> balanceByFriendId = new HashMap<>();
            balanceRepository.findAllByUserIdAndGroupGroupId(userId, group.getGroupId())
                    .forEach(b -> balanceByFriendId.put(b.getFriend().getId(), b));

            List<UserGroupMeta.GroupMemberMeta> membersBalance = new ArrayList<>();
            for (SplitUser member : membersMeta) {
                UserGroupMeta.GroupMemberMeta meta = new UserGroupMeta.GroupMemberMeta();
                meta.setId(member.getId());
                meta.setEmail(member.getEmailId());
                meta.setFirstName(member.getFirstName());
                meta.setLastName(member.getLastName());
                meta.setRegistrationStatus(member.isEmailVerified() ? "verified" : "not_verified");

                Balance memberBalance = balanceByFriendId.get(member.getId());
                if (memberBalance != null) {
                    meta.setBalance(memberBalance.balanceDto());
                }
                membersBalance.add(meta);
            }

            UserGroupMeta groupMeta = new UserGroupMeta();
            groupMeta.setId(group.getGroupId());
            groupMeta.setName(group.getGroupName());
            groupMeta.setCreatedAt(group.getCreatedAt());
            groupMeta.setUpdatedAt(group.getUpdatedAt());
            groupMeta.setGroupType(group.getGroupType() != null ? group.getGroupType().name() : null);
            groupMeta.setCurrencyCode(group.getCurrencyCode() != null ? group.getCurrencyCode().name() : null);
            groupMeta.setMembers(membersBalance);
            result.add(groupMeta);
        }
        return result;
    }

    @Transactional(readOnly = true)
    public List<FriendsDto> getFriendsMeta(long userId) {
        List<FriendsDto> result = new ArrayList<>();
        List<Friends> friendsList = friendsRepository.findAllByUserId(userId);
        List<Balance> userBalance = balanceRepository.findAllByUserId(userId);

        Map<Long, Balance> friendVsBalance = new HashMap<>();
        Map<Long, List<Balance>> friendVsGroupBalance = new HashMap<>();
        for (Balance balance : userBalance) {
            if (balance.getGroup() == null) {
                friendVsBalance.put(balance.getFriend().getId(), balance);
            } else {
                friendVsGroupBalance.computeIfAbsent(balance.getFriend().getId(), k -> new ArrayList<>()).add(balance);
            }
        }

        for (Friends friend : friendsList) {
            // Bidirectional query returns rows where userId is either user or friend.
            // Resolve which side is the actual friend of the current user.
            SplitUser friendMeta = friend.getUser().getId().equals(userId)
                    ? friend.getFriend()
                    : friend.getUser();

            if (friendMeta == null) continue;

            FriendsDto dto = new FriendsDto();
            dto.setId(friendMeta.getId());
            dto.setFirstName(friendMeta.getFirstName());
            dto.setLastName(friendMeta.getLastName());
            dto.setUserName(friendMeta.getUsername());
            dto.setEmailId(friendMeta.getEmailId());
            dto.setRegistrationStatus(friendMeta.isEmailVerified() ? "verified" : "not_verified");

            Balance personalBalance = friendVsBalance.get(friendMeta.getId());
            if (personalBalance != null) {
                dto.setBalanceDto(personalBalance.balanceDto());
            }

            List<FriendsDto.FriendsGroupDto> groupBalances = new ArrayList<>();
            List<Balance> groupBalanceList = friendVsGroupBalance.getOrDefault(friendMeta.getId(), List.of());
            for (Balance groupBalance : groupBalanceList) {
                FriendsDto.FriendsGroupDto groupDto = new FriendsDto.FriendsGroupDto();
                groupDto.setBalanceDto(groupBalance.balanceDto());
                groupDto.setGroupId(groupBalance.getGroup().getGroupId());
                groupBalances.add(groupDto);
            }
            dto.setGroups(groupBalances);
            result.add(dto);
        }
        return result;
    }
}

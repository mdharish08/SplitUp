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
import org.springframework.transaction.annotation.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

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
    public UserGroupMeta createGroup(Long userId, UserGroupMeta groupMeta) {
        if (groupMeta == null || groupMeta.getName() == null || groupMeta.getName().isBlank()) {
            throw new IllegalArgumentException("Group name is required");
        }
        if (groupMeta.getMembers() == null || groupMeta.getMembers().isEmpty()) {
            throw new IllegalArgumentException("At least one member is required");
        }
        if (groupMeta.getGroupType() == null) {
            throw new IllegalArgumentException("Group type is required");
        }
        if (groupMeta.getCurrencyCode() == null) {
            throw new IllegalArgumentException("Currency code is required");
        }

        AppConstants.GroupType groupType;
        AppConstants.CurrencyCode currencyCode;
        try {
            groupType = AppConstants.GroupType.valueOf(groupMeta.getGroupType());
            currencyCode = AppConstants.CurrencyCode.valueOf(groupMeta.getCurrencyCode());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid groupType or currencyCode: " + e.getMessage());
        }

        userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));

        List<Long> memberIds = new ArrayList<>();
        for (UserGroupMeta.GroupMemberMeta member : groupMeta.getMembers()) {
            if (member.getId() == null) {
                throw new IllegalArgumentException("Each member must have an id");
            }
            memberIds.add(member.getId());
        }

        List<SplitUser> members = userRepository.findAllById(memberIds);
        if (members.size() != memberIds.size()) {
            throw new IllegalArgumentException("One or more members not found");
        }

        Timestamp now = Timestamp.from(Instant.now());
        Group group = Group.builder()
                .withGroupName(groupMeta.getName())
                .withGroupType(groupType)
                .withCurrencyCode(currencyCode)
                .withCreatedBy(userId)
                .withGroupDescription(groupMeta.getDescription())
                .withCreatedAt(now)
                .withUpdatedAt(now)
                .build();
        groupRepository.save(group);

        List<GroupMapping> mappings = members.stream()
                .map(m -> GroupMapping.builder().withGroup(group).withMember(m).build())
                .toList();
        groupMappingRepository.saveAll(mappings);

        List<Balance> balances = new ArrayList<>();
        for (SplitUser member : members) {
            for (SplitUser friend : members) {
                if (!member.equals(friend)) {
                    balances.add(Balance.builder()
                            .withGroup(group)
                            .withUser(member)
                            .withFriend(friend)
                            .withAmount(BigDecimal.ZERO)
                            .withCurrencyCode(currencyCode)
                            .build());
                }
            }
        }
        balanceRepository.saveAll(balances);

        List<UserGroupMeta.GroupMemberMeta> membersMeta = members.stream().map(m -> {
            UserGroupMeta.GroupMemberMeta meta = new UserGroupMeta.GroupMemberMeta();
            meta.setId(m.getId());
            meta.setEmail(m.getEmailId());
            meta.setFirstName(m.getFirstName());
            meta.setLastName(m.getLastName());
            meta.setRegistrationStatus(m.isEmailVerified() ? "verified" : "not_verified");
            return meta;
        }).toList();

        groupMeta.setId(group.getGroupId());
        groupMeta.setMembers(membersMeta);
        groupMeta.setCreatedAt(group.getCreatedAt());
        groupMeta.setUpdatedAt(group.getUpdatedAt());
        return groupMeta;
    }
}

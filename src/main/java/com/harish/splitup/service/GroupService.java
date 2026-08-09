package com.harish.splitup.service;

import com.harish.splitup.dto.CreateGroupRequestDto;
import com.harish.splitup.dto.GroupMetaResponseDto;
import com.harish.splitup.entities.Balance;
import com.harish.splitup.entities.Group;
import com.harish.splitup.entities.GroupMapping;
import com.harish.splitup.entities.SplitUser;
import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.repositories.BalanceRepository;
import com.harish.splitup.repositories.GroupMappingRepository;
import com.harish.splitup.repositories.GroupRepository;
import com.harish.splitup.repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GroupService {

    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final GroupMappingRepository groupMappingRepository;
    private final BalanceRepository balanceRepository;

    @Transactional
    public GroupMetaResponseDto createGroup(Long userId, CreateGroupRequestDto req) {
        if (req == null || req.name() == null || req.name().isBlank()) {
            throw new IllegalArgumentException("Group name is required");
        }
        if (req.members() == null || req.members().isEmpty()) {
            throw new IllegalArgumentException("At least one member is required");
        }
        if (req.groupType() == null) {
            throw new IllegalArgumentException("Group type is required");
        }
        if (req.currencyCode() == null) {
            throw new IllegalArgumentException("Currency code is required");
        }

        List<Long> memberIds = new ArrayList<>();
        for (CreateGroupRequestDto.GroupMemberRequestDto member : req.members()) {
            if (member.id() == null) {
                throw new IllegalArgumentException("Each member must have an id");
            }
            memberIds.add(member.id());
        }

        Set<Long> requiredUserIds = new LinkedHashSet<>(memberIds);
        requiredUserIds.add(userId);
        Map<Long, SplitUser> usersById = userRepository.findAllById(requiredUserIds).stream()
                .collect(Collectors.toMap(SplitUser::getId, Function.identity()));

        if (!usersById.containsKey(userId)) {
            throw new NoSuchElementException("User not found: " + userId);
        }

        List<SplitUser> members = new ArrayList<>();
        for (Long memberId : memberIds) {
            SplitUser member = usersById.get(memberId);
            if (member == null) {
                throw new IllegalArgumentException("One or more members not found");
            }
            members.add(member);
        }

        Timestamp now = Timestamp.from(Instant.now());
        Group group = Group.builder()
                .withGroupName(req.name())
                .withGroupType(req.groupType())
                .withCurrencyCode(req.currencyCode())
                .withCreatedBy(userId)
                .withGroupDescription(req.description())
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
                            .withCurrencyCode(req.currencyCode())
                            .build());
                }
            }
        }
        balanceRepository.saveAll(balances);

        List<GroupMetaResponseDto.GroupMemberResponseDto> membersMeta = members.stream()
                .map(m -> new GroupMetaResponseDto.GroupMemberResponseDto(
                        m.getId(),
                        m.getEmailId(),
                        m.getFirstName(),
                        m.getLastName(),
                        m.getAccountStatus() == AppConstants.AccountStatus.INVITED
                                ? "pending"
                                : (m.isEmailVerified() ? "verified" : "not_verified"),
                        null
                ))
                .toList();

        return new GroupMetaResponseDto(
                group.getGroupId(),
                group.getGroupName(),
                group.getGroupType(),
                group.getCurrencyCode(),
                group.getGroupDescription(),
                group.getCreatedAt(),
                group.getUpdatedAt(),
                membersMeta
        );
    }
}

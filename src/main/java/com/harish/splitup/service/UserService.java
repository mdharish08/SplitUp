package com.harish.splitup.service;

import com.harish.splitup.constants.AppConstants;
import com.harish.splitup.dto.AddFriendRequestDto;
import com.harish.splitup.dto.FriendsDto;
import com.harish.splitup.dto.SignupRequestDto;
import com.harish.splitup.dto.UserDto;
import com.harish.splitup.dto.UserGroupMeta;
import com.harish.splitup.entities.*;
import com.harish.splitup.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

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

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private PendingFriendInviteRepository pendingInviteRepository;

    @Transactional
    public UserDto registerUser(SignupRequestDto req) {
        if (userRepository.findByEmailId(req.getEmailId()).isPresent()) {
            throw new IllegalStateException("Email already registered: " + req.getEmailId());
        }
        SplitUser user = SplitUser.builder()
                .withFirstName(req.getFirstName())
                .withLastName(req.getLastName())
                .withEmailId(req.getEmailId())
                .withUserPassWord(passwordEncoder.encode(req.getPassword()))
                .build();
        userRepository.save(user);

        // Convert any pending invites that were sent to this email into real friendships
        List<PendingFriendInvite> pendingInvites =
                pendingInviteRepository.findAllByInviteeEmail(req.getEmailId());

        if (!pendingInvites.isEmpty()) {
            Timestamp now = new Timestamp(System.currentTimeMillis());
            List<Friends> newFriendships = new ArrayList<>();
            List<Balance> newBalances = new ArrayList<>();

            for (PendingFriendInvite invite : pendingInvites) {
                SplitUser inviter = invite.getInviter();

                Friends friendship = Friends.builder()
                        .withUser(inviter)
                        .withFriend(user)
                        .withCreatedAt(now)
                        .withUpdatedAt(now)
                        .withTrashed(false)
                        .build();
                newFriendships.add(friendship);

                AppConstants.CurrencyCode currency =
                        invite.getCurrencyCode() != null ? invite.getCurrencyCode() : AppConstants.CurrencyCode.USD;

                newBalances.add(Balance.builder()
                        .withUser(inviter)
                        .withFriend(user)
                        .withAmount(BigDecimal.ZERO)
                        .withCurrencyCode(currency)
                        .build());
                newBalances.add(Balance.builder()
                        .withUser(user)
                        .withFriend(inviter)
                        .withAmount(BigDecimal.ZERO)
                        .withCurrencyCode(currency)
                        .build());
            }

            friendsRepository.saveAll(newFriendships);
            balanceRepository.saveAll(newBalances);
            pendingInviteRepository.deleteAll(pendingInvites);
        }

        return user.toDTO();
    }

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

        // Append pending (not-yet-registered) invites sent by this user
        List<PendingFriendInvite> pendingInvites = pendingInviteRepository.findAllByInviterId(userId);
        for (PendingFriendInvite invite : pendingInvites) {
            FriendsDto dto = new FriendsDto();
            // id is intentionally null — the invitee has no account yet
            dto.setEmailId(invite.getInviteeEmail());
            dto.setFirstName(invite.getInviteeEmail()); // display email as name until they sign up
            dto.setRegistrationStatus("pending");
            dto.setGroups(new ArrayList<>());
            result.add(dto);
        }

        return result;
    }

    @Transactional
    public FriendsDto addFriend(long userId, AddFriendRequestDto req) {
        if (req.getEmailId() == null || req.getEmailId().isBlank()) {
            throw new IllegalArgumentException("Friend email is required");
        }

        SplitUser currentUser = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));

        if (req.getEmailId().equalsIgnoreCase(currentUser.getEmailId())) {
            throw new IllegalArgumentException("You cannot add yourself as a friend");
        }

        AppConstants.CurrencyCode currencyCode = req.getCurrencyCode() != null
                ? AppConstants.CurrencyCode.valueOf(req.getCurrencyCode())
                : AppConstants.CurrencyCode.USD;

        SplitUser friendUser = userRepository.findByEmailId(req.getEmailId()).orElse(null);

        if (friendUser == null) {
            // Invitee not registered yet — create a pending invite
            if (pendingInviteRepository.findByInviterIdAndInviteeEmail(userId, req.getEmailId()).isPresent()) {
                throw new IllegalStateException("You already sent an invite to this email");
            }

            Timestamp now = new Timestamp(System.currentTimeMillis());
            PendingFriendInvite invite = PendingFriendInvite.builder()
                    .withInviter(currentUser)
                    .withInviteeEmail(req.getEmailId())
                    .withCurrencyCode(currencyCode)
                    .withCreatedAt(now)
                    .build();
            pendingInviteRepository.save(invite);

            // Return a DTO signalling the invite is pending
            FriendsDto dto = new FriendsDto();
            dto.setEmailId(req.getEmailId());
            dto.setFirstName(req.getEmailId());
            dto.setRegistrationStatus("pending");
            dto.setGroups(new ArrayList<>());
            return dto;
        }

        // Invitee already registered — create friendship immediately
        if (friendsRepository.findExisting(userId, friendUser.getId()).isPresent()) {
            throw new IllegalStateException("You are already friends with this user");
        }

        Timestamp now = new Timestamp(System.currentTimeMillis());
        Friends friendship = Friends.builder()
                .withUser(currentUser)
                .withFriend(friendUser)
                .withCreatedAt(now)
                .withUpdatedAt(now)
                .withTrashed(false)
                .build();
        friendsRepository.save(friendship);

        Balance userToFriend = Balance.builder()
                .withUser(currentUser)
                .withFriend(friendUser)
                .withAmount(BigDecimal.ZERO)
                .withCurrencyCode(currencyCode)
                .build();
        Balance friendToUser = Balance.builder()
                .withUser(friendUser)
                .withFriend(currentUser)
                .withAmount(BigDecimal.ZERO)
                .withCurrencyCode(currencyCode)
                .build();
        balanceRepository.saveAll(List.of(userToFriend, friendToUser));

        FriendsDto dto = new FriendsDto();
        dto.setId(friendUser.getId());
        dto.setFirstName(friendUser.getFirstName());
        dto.setLastName(friendUser.getLastName());
        dto.setUserName(friendUser.getUsername());
        dto.setEmailId(friendUser.getEmailId());
        dto.setRegistrationStatus(friendUser.isEmailVerified() ? "verified" : "not_verified");
        dto.setBalanceDto(userToFriend.balanceDto());
        dto.setGroups(new ArrayList<>());
        return dto;
    }
}

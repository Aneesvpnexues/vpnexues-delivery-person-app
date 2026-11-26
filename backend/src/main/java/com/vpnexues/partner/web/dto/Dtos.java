package com.vpnexues.partner.web.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.util.List;

/** Request payloads for the partner API and the ops console. */
public final class Dtos {
    private Dtos() {}

    // ---- Auth ----
    public record SignupStart(
            @NotBlank String fullName,
            @NotBlank String phone,
            @NotNull Integer cityId,
            @NotBlank String vehicleType,
            String referralCode,
            Boolean acceptedTerms) {}

    public record SignupVerify(@NotBlank String phone, @NotBlank String code) {}

    public record PasswordBody(@NotBlank String password) {}

    public record LoginBody(@NotBlank String phone, @NotBlank String password) {}

    public record PhoneBody(@NotBlank String phone) {}

    public record ResetVerify(@NotBlank String phone, @NotBlank String code, @NotBlank String password) {}

    public record RefreshBody(@NotBlank String refreshToken) {}

    // ---- Partner ----
    public record UpdateMe(String email, String dateOfBirth, String bloodGroup, String address, String language) {}

    public record OnlineBody(@NotNull Boolean online) {}

    public record SettingsBody(Boolean autoAcceptNearby, String navigationApp, Boolean newOrderSound,
                               Boolean payoutAlerts, Boolean offersCampaigns, Boolean darkModeAtNight,
                               Boolean dataSaver, Boolean voiceNavigation, Boolean fingerprintUnlock) {}

    public record RadiusBody(@NotNull Integer radiusKm) {}

    public record ChangeRequest(@NotNull Integer cityId, String hubId) {}

    public record DeviceBody(@NotBlank String platform, @NotBlank String token) {}

    // ---- Documents ----
    public record UploadUrlBody(@NotBlank String contentType, String side) {}

    public record SubmitDoc(List<String> s3Keys, String number, String validUntil, Boolean consent) {}

    public record VehicleBody(@NotBlank String type, @NotBlank String registrationNumber,
                              String makeModel, Integer year, String colour, String fuel) {}

    // ---- Money ----
    public record PayoutMethodBody(String type, String accountHolderName, String accountNumber,
                                   String confirmAccountNumber, String ifsc, String bankName, String branch,
                                   String accountType, Boolean makePrimary, Boolean keepBankAsBackup, String upiVpa) {}

    public record InstantPayout(@NotNull Long amountPaise, String payoutMethodId) {}

    // ---- Orders ----
    public record LocBody(@DecimalMin("-90") @DecimalMax("90") Double lat,
                          @DecimalMin("-180") @DecimalMax("180") Double lng) {}

    public record ScanBody(@NotBlank String qrCode, Boolean damaged) {}

    public record DeliverBody(@NotBlank @Pattern(regexp = "\\d{4}") String code,
                              @DecimalMin("-90") @DecimalMax("90") Double lat,
                              @DecimalMin("-180") @DecimalMax("180") Double lng) {}

    public record FeedbackBody(@NotBlank String dropOffEase) {}

    // ---- Engagement ----
    public record TicketBody(@NotBlank String topic, @NotBlank String message, String orderId) {}

    public record MessageBody(@NotBlank String message) {}

    public record SosBody(String kind, Double lat, Double lng, String orderId, String details) {}

    public record ContactBody(@NotBlank String name, @NotBlank String relationship, @NotBlank String phone, Boolean isPrimary) {}

    public record RatingBody(@NotNull Integer stars, String comment, String appVersion) {}

    // ---- Admin ----
    public record AdminLogin(@NotBlank String email, @NotBlank String password) {}

    public record AdminPassword(@NotBlank String currentPassword, @NotBlank String newPassword) {}

    public record PartnerPatch(String status, String kycStatus, String hubId, Integer deliveryRadiusKm, String reason) {}

    public record VerificationBody(@NotBlank String verification, String verifiedName) {}

    public record DocReview(@NotBlank String decision, String reason, String validUntil) {}

    public record OrderCreate(
            @NotBlank String hubId,
            @NotBlank @Size(max = 120) String customerName,
            @NotBlank @Pattern(regexp = "^\\+?[0-9]{10,15}$") String customerPhone,
            @NotBlank @Size(max = 240) String dropAddress,
            @NotNull @DecimalMin("-90") @DecimalMax("90") Double dropLat,
            @NotNull @DecimalMin("-180") @DecimalMax("180") Double dropLng,
            @Size(max = 500) String dropInstructions,
            Boolean leaveAtDoor,
            @NotNull @DecimalMin("0") @DecimalMax("1000") Double distanceKm,
            @Min(1) @Max(32767) Integer etaMinutes,
            String scheduledFor,
            @NotNull @PositiveOrZero @Max(2147483647L) Long payBasePaise,
            @NotNull @PositiveOrZero @Max(2147483647L) Long payDistancePaise,
            @NotNull @PositiveOrZero @Max(2147483647L) Long tipPaise,
            @Valid @Size(max = 50) List<Crate> crates,
            String partnerId) {
        public record Crate(@NotBlank @Size(max = 120) String label,
                            @NotNull @Positive @Max(2147483647) Integer weightGrams) {}
    }

    public record AssignBody(@NotBlank String partnerId) {}

    public record CancelBody(@NotBlank String reason) {}

    public record PayoutStatusBody(@NotBlank String status, String utr, String failureReason) {}

    public record TicketStatusBody(@NotBlank String status) {}

    public record SosStatusBody(@NotBlank String status, String note) {}

    public record ZoneDecision(@NotBlank String decision, String hubId, String note) {}

    public record StaffCreate(@NotBlank String email, @NotBlank String fullName, @NotBlank String role, @NotBlank String password) {}

    public record StaffPatch(String role, Boolean isActive) {}
}

package com.vpnexues.partner.service;

import com.vpnexues.partner.common.ApiException;
import com.vpnexues.partner.config.AppProperties;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Map;

/**
 * Document storage. Uses the local filesystem by default so the stack runs with zero cloud
 * dependencies; the presigned-upload contract is identical to S3, so swapping in S3 later only
 * changes this class.
 */
@Service
public class StorageService {
    private final Path root;
    private final String publicBaseUrl;

    public StorageService(AppProperties props) {
        this.root = Path.of(props.uploadDir()).toAbsolutePath().normalize();
        this.publicBaseUrl = props.publicBaseUrl().replaceAll("/$", "");
        try {
            Files.createDirectories(root);
        } catch (IOException e) {
            throw new IllegalStateException("Cannot create upload directory " + root, e);
        }
    }

    public Map<String, Object> presignUpload(String key, String contentType) {
        String url = publicBaseUrl + "/v1/documents/upload?key=" + java.net.URLEncoder.encode(key, java.nio.charset.StandardCharsets.UTF_8);
        return Map.of(
                "url", url,
                "method", "PUT",
                "headers", Map.of("Content-Type", contentType),
                "key", key,
                "expiresIn", 300);
    }

    public void store(String partnerId, String key, byte[] bytes) {
        if (!key.startsWith("partners/" + partnerId + "/documents/")) {
            throw ApiException.badRequest("BAD_S3_KEY", "Upload the file with an upload URL first");
        }
        Path target = resolve(key);
        try {
            Files.createDirectories(target.getParent());
            Files.write(target, bytes, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
        } catch (IOException e) {
            throw new ApiException(500, "STORAGE_FAILED", "Could not save the file");
        }
    }

    public byte[] read(String key) {
        try {
            return Files.readAllBytes(resolve(key));
        } catch (IOException e) {
            throw ApiException.notFound("File");
        }
    }

    private Path resolve(String key) {
        Path target = root.resolve(key).normalize();
        if (!target.startsWith(root)) throw ApiException.badRequest("BAD_S3_KEY", "Invalid file key");
        return target;
    }
}

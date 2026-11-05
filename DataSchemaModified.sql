CREATE TABLE body_segments (
    segment_name VARCHAR(30) NOT NULL,
    CONSTRAINT body_segments_pk PRIMARY KEY (segment_name)
);

CREATE TABLE joints (
    joint_name VARCHAR(30) NOT NULL,
    CONSTRAINT joints_pk PRIMARY KEY (joint_name),
    CONSTRAINT joints_name_template CHECK (
        joint_name ~ '^[A-Za-zА-Яа-яІіЇїЄєҐґ][A-Za-zА-Яа-яІіЇїЄєҐґ -]*$'
    )
);

CREATE TABLE joint_connections (
    joint_name VARCHAR(30) NOT NULL,
    segment_name VARCHAR(30) NOT NULL,
    CONSTRAINT joint_connections_pk PRIMARY KEY (joint_name, segment_name),
    CONSTRAINT joint_connections_joint_fk FOREIGN KEY (joint_name)
    REFERENCES joints (joint_name),
    CONSTRAINT joint_connections_segment_fk FOREIGN KEY (segment_name)
    REFERENCES body_segments (segment_name)
);

CREATE TABLE exercises (
    exercise_name VARCHAR(50) NOT NULL,
    joint_name VARCHAR(30) NOT NULL,
    CONSTRAINT exercises_pk PRIMARY KEY (exercise_name),
    CONSTRAINT exercises_joint_fk FOREIGN KEY (joint_name)
    REFERENCES joints (joint_name)
);

CREATE TABLE safe_ranges (
    exercise_name VARCHAR(50) NOT NULL,
    min_angle NUMERIC(5, 2) NOT NULL,
    max_angle NUMERIC(5, 2) NOT NULL,
    CONSTRAINT safe_ranges_pk PRIMARY KEY (exercise_name),
    CONSTRAINT safe_ranges_exercise_fk FOREIGN KEY (exercise_name)
    REFERENCES exercises (exercise_name),
    CONSTRAINT safe_ranges_min_angle_range CHECK (min_angle BETWEEN 0 AND 180),
    CONSTRAINT safe_ranges_max_angle_range CHECK (max_angle BETWEEN 0 AND 180),
    CONSTRAINT safe_ranges_order CHECK (max_angle >= min_angle)
);

CREATE TABLE warmup_norms (
    exercise_name VARCHAR(50) NOT NULL,
    min_amplitude NUMERIC(5, 2) NOT NULL,
    CONSTRAINT warmup_norms_pk PRIMARY KEY (exercise_name),
    CONSTRAINT warmup_norms_exercise_fk FOREIGN KEY (exercise_name)
    REFERENCES exercises (exercise_name),
    CONSTRAINT warmup_norms_amplitude_range CHECK (
        min_amplitude BETWEEN 0 AND 180
    )
);

CREATE TABLE amplitude_measurements (
    measurement_id INTEGER GENERATED ALWAYS AS IDENTITY,
    joint_name VARCHAR(30) NOT NULL,
    exercise_name VARCHAR(50) NOT NULL,
    amplitude NUMERIC(5, 2) NOT NULL,
    measured_at TIMESTAMP NOT NULL,
    CONSTRAINT amplitude_measurements_pk PRIMARY KEY (measurement_id),
    CONSTRAINT amplitude_measurements_joint_fk FOREIGN KEY (joint_name)
    REFERENCES joints (joint_name),
    CONSTRAINT amplitude_measurements_exercise_fk FOREIGN KEY (exercise_name)
    REFERENCES exercises (exercise_name),
    CONSTRAINT amplitude_measurements_amplitude_range CHECK (
        amplitude BETWEEN 0 AND 180
    )
);

CREATE TABLE technique_violations (
    violation_id INTEGER GENERATED ALWAYS AS IDENTITY,
    measurement_id INTEGER NOT NULL,
    violation_type VARCHAR(20) NOT NULL,
    detected_at TIMESTAMP NOT NULL,
    resolved_at TIMESTAMP,
    CONSTRAINT technique_violations_pk PRIMARY KEY (violation_id),
    CONSTRAINT technique_violations_measurement_uq UNIQUE (measurement_id),
    CONSTRAINT technique_violations_measurement_fk FOREIGN KEY (measurement_id)
    REFERENCES amplitude_measurements (measurement_id),
    CONSTRAINT technique_violations_type_values CHECK (
        violation_type IN ('out_of_range', 'below_norm')
    ),
    CONSTRAINT technique_violations_resolved_order CHECK (
        resolved_at IS NULL OR resolved_at >= detected_at
    )
);

CREATE TABLE warnings (
    warning_id INTEGER GENERATED ALWAYS AS IDENTITY,
    violation_id INTEGER NOT NULL,
    message_text VARCHAR(200) NOT NULL,
    instruction VARCHAR(10) NOT NULL,
    CONSTRAINT warnings_pk PRIMARY KEY (warning_id),
    CONSTRAINT warnings_violation_fk FOREIGN KEY (violation_id)
    REFERENCES technique_violations (violation_id),
    CONSTRAINT warnings_message_template CHECK (
        message_text ~ '^[^[:space:]](.*[^[:space:]])?$'
    ),
    CONSTRAINT warnings_instruction_values CHECK (
        instruction IN ('increase', 'decrease')
    )
);
